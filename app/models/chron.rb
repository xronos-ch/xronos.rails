# frozen_string_literal: true

# Abstract base class for scientific dating records (e.g. C14, Typo).
# Provides the shared cross-sample chron dedup framework; subclasses
# declare only the attributes unique to their dating method.
class Chron < ApplicationRecord # rubocop:disable Metrics/ClassLength
  self.abstract_class = true

  include Versioned
  include Supersedable
  include Mergeable

  belongs_to :sample
  delegate :context, to: :sample
  delegate :site, to: :sample

  has_many :citations, as: :citing, dependent: :destroy
  has_many :references, through: :citations

  after_save :merge_exact_duplicates
  after_save :merge_cross_sample_duplicates

  before_merge :reassign_citations!

  acts_as_copy_target

  def self.label
    raise NotImplementedError, "#{name} must implement .label"
  end

  def self.icon
    raise NotImplementedError, "#{name} must implement .icon"
  end

  # Rake task entry point. Uses a single self-join to find all
  # cross-sample candidate pairs in one SQL query, then iterates
  # only those pairs. Picked up by xronos:deduplicate via
  # `respond_to?(:cross_sample_deduplicate?)` and skipped for other
  # Mergeable models.
  def self.cross_sample_deduplicate!
    cross_sample_pairs.each do |chron_id, other_chron_id|
      chron = unscoped.find(chron_id)
      next unless chron
      next if chron.superseded?

      other = unscoped.find(other_chron_id)
      next unless other
      next if other.superseded?
      # Skip stale pairs: a previous iteration may have merged
      # `other`'s sample into `chron`'s sample (or vice versa),
      # leaving both chrons in the same sample.
      next if chron.sample_id == other.sample_id

      chron.merge_cross_sample_duplicates(cross_sample_target_sample: other.sample)
    end
  end

  # Self-join that returns every cross-sample candidate pair
  # `(chron_id, other_chron_id)` exactly once — the younger chron
  # (by `(created_at, id)`, matching `Mergeable#merge_with_duplicate`'s
  # canonicality rule) is on the left. Uses the composite index
  # `(lab_identifier, sample_id, created_at)` (and the equivalent
  # for typos) added in db/migrate/2026070712000* for the join key.
  def self.cross_sample_pairs
    sql = +<<~SQL
      SELECT c1.id AS chron_id, c2.id AS other_chron_id
      FROM #{table_name} c1
      INNER JOIN #{table_name} c2 ON #{cross_sample_pairs_on_clause.join(' AND ')}
        AND (c1.created_at, c1.id) > (c2.created_at, c2.id)
    SQL
    where = cross_sample_pairs_where_clause
    sql << " WHERE #{where}" if where

    connection.select_all(sql).map { |r| [r['chron_id'].to_i, r['other_chron_id'].to_i] }
  end

  # `ON` clause for the cross-sample self-join: per-attr join (strict:
  # `=`, nil_matches_nil: `IS NOT DISTINCT FROM`) + same-chron /
  # same-sample exclusions.
  def self.cross_sample_pairs_on_clause
    attrs    = exact_duplicates_attrs - [:sample_id]
    nil_safe = exact_duplicates_nil_matches_nil.to_set
    q        = ->(c) { connection.quote_column_name(c) }
    attr_conds = attrs.map do |a|
      c = q.call(a)
      nil_safe.include?(a) ? "c2.#{c} IS NOT DISTINCT FROM c1.#{c}" : "c2.#{c} = c1.#{c}"
    end
    attr_conds + ['c2.sample_id != c1.sample_id', 'c2.id != c1.id']
  end

  # `WHERE` clause mirroring the per-row `cross_sample_attr_unmatchable?`
  # guard: chrons whose strict attrs are NULL can never match.
  def self.cross_sample_pairs_where_clause
    strict = (exact_duplicates_attrs - exact_duplicates_nil_matches_nil) - [:sample_id]
    return nil if strict.empty?

    q = ->(c) { connection.quote_column_name(c) }
    strict.map { |a| "c1.#{q.call(a)} IS NOT NULL" }.join(' AND ')
  end

  # Fallback for the case where a chron's duplicate lives in a
  # different sample because both samples were left unnamed. The two
  # samples are merged (the older one survives; the younger one's
  # chrons are reassigned to it), and the chron duplicate is then
  # detected and merged on the standard same-sample path.
  #
  # `cross_sample_target_sample` is an optional pre-computed target
  # used by `cross_sample_deduplicate!` to skip the per-chron
  # `find_cross_sample_chron_duplicate_sample` query. It is `nil`
  # when invoked from the `after_save` callback, in which case the
  # target is discovered via the per-chron query as before.
  def merge_cross_sample_duplicates(cross_sample_target_sample: nil)
    return if superseded?

    cross_sample_target = cross_sample_target_sample ||
                          find_cross_sample_chron_duplicate_sample
    return unless cross_sample_target

    Sample.merge_duplicates!([sample, cross_sample_target])
    reload

    dupe = find_exact_duplicate
    return unless dupe

    merge_with_duplicate(dupe)
  end

  private

  def reassign_citations!
    Citation.reassign_all_to!(from: self, to: canonical)
  end

  # Find a chron in a different sample that would be a duplicate
  # except for sample_id, and whose parent sample is a
  # "name-relaxed" duplicate of self.sample (see
  # Sample#name_relaxed_duplicate_of?). Returns the parent sample of
  # the oldest matching chron, or nil if no match.
  def find_cross_sample_chron_duplicate_sample
    return nil if sample_id.nil?

    query = cross_sample_chron_query
    return nil unless query

    match = query.first
    return nil unless match
    return nil unless sample.name_relaxed_duplicate_of?(match.sample)

    match.sample
  end

  def cross_sample_chron_query
    chron_attrs = cross_sample_chron_attrs
    query       = base_cross_sample_query

    chron_attrs.each do |attr, val|
      return nil if cross_sample_attr_unmatchable?(attr, val)

      query = query.where(attr => val)
    end

    query
  end

  def cross_sample_chron_attrs
    attrs = attributes.with_indifferent_access
    (self.class.exact_duplicates_attrs - [:sample_id]).map(&:to_s).index_with { |a| attrs[a] }
  end

  def base_cross_sample_query
    self.class.where.not(id: id)
        .where.not(sample_id: sample_id)
        .order(:created_at, :id)
  end

  def cross_sample_attr_unmatchable?(attr, val)
    val.nil? && !self.class.exact_duplicates_attrs_with_options[attr.to_sym]
  end
end
