# frozen_string_literal: true

# == Schema Information
#
# Table name: samples
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  name                 :string
#  part_of_organism     :text
#  position_crs         :text
#  position_description :text
#  position_x           :decimal(, )
#  position_y           :decimal(, )
#  position_z           :decimal(, )
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  context_id           :integer
#  material_id          :integer
#  taxon_id             :integer
#
# Indexes
#
#  index_samples_on_context_id    (context_id)
#  index_samples_on_material_id   (material_id)
#  index_samples_on_position_crs  (position_crs)
#  index_samples_on_taxon_id      (taxon_id)
#

class Sample < ApplicationRecord
  include Versioned
  include HasControlledTerms
  include Mergeable

  controlled_term :part_of_organism, vocabulary: 'part_of_organism'

  exact_duplicates_on :name, :context_id,
                      material_id: :nil_matches_nil,
                      taxon_id: :nil_matches_nil,
                      part_of_organism: :nil_matches_nil,
                      position_description: :nil_matches_nil,
                      position_crs: :nil_matches_nil,
                      position_x: :nil_matches_nil,
                      position_y: :nil_matches_nil,
                      position_z: :nil_matches_nil

  before_validation :normalise_name

  delegate :site, to: :context

  belongs_to :context, optional: true
  accepts_nested_attributes_for :context, reject_if: proc { |attributes|
    attributes.all? do |key, value|
      key == '_destroy' || value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?))
    end
  }
  validates_associated :context

  belongs_to :material, optional: true
  accepts_nested_attributes_for :material, reject_if: :all_blank
  validates_associated :material
  delegate :name, to: :material, prefix: true, allow_nil: true

  belongs_to :taxon, optional: true
  accepts_nested_attributes_for :taxon, reject_if: :all_blank
  validates_associated :taxon
  delegate :name, to: :taxon, prefix: true, allow_nil: true

  after_destroy :destroy_material_if_orphaned
  after_destroy :destroy_taxon_if_orphaned

  has_many :c14s, dependent: :destroy
  has_many :typos, dependent: :destroy

  after_save :merge_exact_duplicates
  validate :no_exact_duplicate, on: :create

  before_merge :reassign_c14s!
  before_merge :reassign_typos!

  include PgSearch::Model
  pg_search_scope :search,
                  against: :position_description,
                  using: { tsearch: { prefix: true } } # match partial words
  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = %i[missing_material missing_taxon missing_crs]

  def self.label
    'sample'
  end

  def label
    name
  end

  def destroy_material_if_orphaned
    return if material.nil?

    material.destroy_if_orphaned
  end

  def destroy_taxon_if_orphaned
    return if taxon.nil?

    taxon.destroy_if_orphaned
  end

  def gbif_taxon_uri
    return nil if taxon.blank? || taxon.gbif_id.blank?

    "gbif:#{taxon.gbif_id}"
  end

  scope :missing_material, -> { where(material_id: nil) }
  def missing_material?
    material.blank?
  end

  scope :missing_taxon, -> { where(taxon_id: nil) }
  def missing_taxon?
    taxon.blank?
  end

  scope :missing_crs, lambda {
    where('position_crs IS NULL AND (position_x IS NOT NULL OR position_y IS NOT NULL OR position_z IS NOT NULL)')
  }
  def missing_crs?
    if position_x.blank? && position_y.blank? && position_z.blank?
      false
    else
      position_crs.blank?
    end
  end

  # Detects the case where two otherwise-duplicate chrons ended up in
  # samples that share context and other metadata but were both left
  # unnamed. The SQL form lives in
  # `Sample.name_relaxed_duplicate_match_conditions`.
  def name_relaxed_duplicate_of?(other_sample)
    return false unless other_sample.is_a?(Sample) && id != other_sample.id
    return false unless name.nil? && other_sample.name.nil? || name == other_sample.name

    (self.class.exact_duplicates_attrs - [:name]).all? { |a| attr_matches?(other_sample, a) }
  end

  # SQL form of `#name_relaxed_duplicate_of?`: every sample
  # exact-duplicate attr except `:name` must match under
  # `Duplicable#match_conditions`'s nil rule; `:name` is allowed to
  # be nil == nil.
  def self.name_relaxed_duplicate_match_conditions(current_alias:, other_alias:, quote:)
    conds = match_conditions(
      attrs: exact_duplicates_attrs - [:name],
      current_alias: current_alias,
      other_alias: other_alias,
      quote: quote
    )
    conds << "(#{current_alias}.name IS NULL AND #{other_alias}.name IS NULL " \
             "OR #{current_alias}.name = #{other_alias}.name)"
    conds
  end

  private

  def normalise_name
    self.name = name.to_s.strip.presence
  end

  def reassign_c14s!
    C14.where(sample_id: id).update_all(sample_id: merged_into_id)
  end

  def reassign_typos!
    Typo.where(sample_id: id).update_all(sample_id: merged_into_id)
  end
end
