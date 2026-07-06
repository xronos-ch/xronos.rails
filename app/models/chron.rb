# frozen_string_literal: true

# Abstract base class for scientific dating records (e.g. C14, Typo).
# Provides the shared cross-sample chron dedup framework; subclasses
# declare only the attributes unique to their dating method.
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

  before_merge :reassign_citations!

  acts_as_copy_target

  def self.label
    raise NotImplementedError, "#{name} must implement .label"
  end

  def self.icon
    raise NotImplementedError, "#{name} must implement .icon"
  end

  # Rake task entry point. Walks every chron and runs the same-sample
  # then cross-sample merge passes. Picked up by xronos:deduplicate
  # via `respond_to?(:cross_sample_deduplicate?)` and skipped for
  # other Mergeable models.
  def self.cross_sample_deduplicate!
    find_each do |chron|
      chron.merge_exact_duplicates
      chron.merge_cross_sample_duplicates
    end
  end

  # Fallback for the case where a chron's duplicate lives in a
  # different sample because both samples were left unnamed. The two
  # samples are merged (the older one survives; the younger one's
  # chrons are reassigned to it), and the chron duplicate is then
  # detected and merged on the standard same-sample path.
  def merge_cross_sample_duplicates
    return if superseded?

    cross_sample_target = find_cross_sample_chron_duplicate_sample
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
