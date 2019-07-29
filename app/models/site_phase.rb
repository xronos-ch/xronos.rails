class SitePhase < ApplicationRecord
  validates :name, presence: true
  has_many :arch_objects, inverse_of: :site_phase
  belongs_to :site
  accepts_nested_attributes_for :site, reject_if: :all_blank
  validates_associated :site
  has_and_belongs_to_many :periods
  accepts_nested_attributes_for :periods, reject_if: :all_blank
  validates_associated :periods
  has_and_belongs_to_many :typochronological_units
  accepts_nested_attributes_for :typochronological_units, reject_if: :all_blank
  validates_associated :typochronological_units
  has_and_belongs_to_many :ecochronological_units
  accepts_nested_attributes_for :ecochronological_units, reject_if: :all_blank
  validates_associated :ecochronological_units
  belongs_to :site_type, optional: true
  accepts_nested_attributes_for :site_type, reject_if: :all_blank, allow_destroy: true
  validates_associated :site_type
end
