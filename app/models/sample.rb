# == Schema Information
#
# Table name: samples
#
#  id                   :bigint           not null, primary key
#  position_crs         :text
#  position_description :text
#  position_x           :decimal(, )
#  position_y           :decimal(, )
#  position_z           :decimal(, )
#  superseded_by        :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  context_id           :integer
#  material_id          :integer
#  taxon_id             :integer
#
# Indexes
#
#  index_samples_on_context_id     (context_id)
#  index_samples_on_material_id    (material_id)
#  index_samples_on_position_crs   (position_crs)
#  index_samples_on_superseded_by  (superseded_by)
#  index_samples_on_taxon_id       (taxon_id)
#
class Sample < ApplicationRecord

  delegate :site, to: :context
  
  belongs_to :context, optional: true
  accepts_nested_attributes_for :context, :reject_if => proc { |attributes| attributes.all? { |key, value| key == "_destroy" || value.blank? || (value.is_a?(Hash) && value.values.all?(&:blank?)) } }
  validates_associated :context

  belongs_to :material, optional: true
  accepts_nested_attributes_for :material, reject_if: :all_blank
  validates_associated :material

  belongs_to :taxon, optional: true
  accepts_nested_attributes_for :taxon, reject_if: :all_blank
  validates_associated :taxon

  has_many :c14s
  has_many :typos

  include Versioned

  acts_as_copy_target # enable CSV exports

  include HasIssues
  @issues = [ :missing_taxon ]
  
  scope :missing_taxon, -> { where(taxon_id: nil) }
  def missing_taxon?
    taxon.blank?
  end

  def self.label
    "sample"
  end
end
