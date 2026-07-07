# frozen_string_literal: true

# Abstract base class for scientific dating records (e.g. C14, Typo).
# Provides the cross-sample dedup framework; subclasses declare only
# what is unique to their dating method.
class Chron < ApplicationRecord
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
  validate :no_exact_duplicate, on: :create

  before_merge :reassign_citations!

  acts_as_copy_target

  def self.label
    raise NotImplementedError, "#{name} must implement .label"
  end

  def self.icon
    raise NotImplementedError, "#{name} must implement .icon"
  end

  # Picked up by `xronos:deduplicate` via `respond_to?`; other
  # Mergeable models are unaffected.
  def self.cross_sample_deduplicate!
    cross_sample_pairs.each do |chron_id, other_chron_id|
      chron = unscoped.find(chron_id)
      next unless chron && !chron.superseded?

      other = unscoped.find(other_chron_id)
      next unless other && !other.superseded?
      # An earlier iteration may have merged `other`'s sample into
      # `chron`'s sample (or vice versa); the pair is now stale.
      next if chron.sample_id == other.sample_id

      chron.merge_cross_sample_duplicates(cross_sample_target_sample: other.sample)
    end
  end

  def self.cross_sample_pairs
    connection.select_all(cross_sample_pair_sql).map do |r|
      [r['chron_id'].to_i, r['other_chron_id'].to_i]
    end
  end

  # Single self-join returning `(chron_id, other_chron_id)` candidate
  # pairs for cross-sample dedup, with the younger chron on the left
  # (matches `Mergeable#merge_with_duplicate`'s canonicality rule).
  # The chron-side join uses the composite index on
  # `(lab_identifier, sample_id, created_at)` (or the Typo equivalent)
  # added in db/migrate/2026070712000*; the sample-side conditions
  # implement `Sample#name_relaxed_duplicate_of?` so the candidates
  # are the same set the per-chron callback would find.
  #
  # When `for_id:` is given, the query is parameterised to the single
  # chron (at most one row) and is used by the `after_save` callback.
  # Both paths share the same `ON`/`WHERE` clauses so the matching
  # rules live in exactly one place.
  def self.cross_sample_pair_sql(for_id: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    quote = ->(c) { connection.quote_column_name(c) }
    chron_attrs  = exact_duplicates_attrs - [:sample_id]
    chron_strict = chron_attrs - exact_duplicates_nil_matches_nil

    chron_on = match_conditions(
      attrs: chron_attrs, current_alias: 'c1', other_alias: 'c2', quote: quote
    ) + [
      'c2.sample_id != c1.sample_id',
      'c2.id != c1.id',
      '(c1.created_at, c1.id) > (c2.created_at, c2.id)'
    ]

    sample_on = Sample.name_relaxed_duplicate_match_conditions(
      current_alias: 's1', other_alias: 's2', quote: quote
    )

    where_clauses = []
    where_clauses << chron_strict.map { |a| "c1.#{quote.call(a)} IS NOT NULL" }.join(' AND ') unless chron_strict.empty?
    where_clauses << ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['c1.id = ?', for_id]) if for_id
    where_sql = where_clauses.empty? ? '' : " WHERE #{where_clauses.join(' AND ')}"

    +<<~SQL
      SELECT c1.id AS chron_id, c2.id AS other_chron_id
      FROM #{table_name} c1
      INNER JOIN #{table_name} c2 ON #{chron_on.join(' AND ')}
      INNER JOIN samples s1 ON s1.id = c1.sample_id
      INNER JOIN samples s2 ON s2.id = c2.sample_id AND #{sample_on.join(' AND ')}#{where_sql}
    SQL
  end

  # Merge self with the chron in another sample that shares every
  # exact-duplicate attribute (except sample_id) and whose parent
  # sample is a name-relaxed duplicate of self.sample. The two
  # samples are merged first; the chron duplicate is then resolved
  # on the standard same-sample path.
  #
  # `cross_sample_target_sample:` is an optional pre-computed target
  # supplied by `cross_sample_deduplicate!`; when `nil` (e.g. from the
  # `after_save` callback) the target is looked up from the same
  # `cross_sample_pair_sql` query.
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

  def find_cross_sample_chron_duplicate_sample
    return nil if sample_id.nil?

    row = self.class.connection.select_one(self.class.cross_sample_pair_sql(for_id: id))
    return nil unless row

    self.class.find(row['other_chron_id']).sample
  end
end
