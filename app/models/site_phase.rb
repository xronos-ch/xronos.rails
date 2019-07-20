class SitePhase < ApplicationRecord
  has_many :arch_objects, inverse_of: :site_phase
  belongs_to :site
  accepts_nested_attributes_for :site, reject_if: :all_blank
  has_and_belongs_to_many :periods
  accepts_nested_attributes_for :periods, reject_if: :all_blank
  has_and_belongs_to_many :typochronological_units
  accepts_nested_attributes_for :typochronological_units, reject_if: :all_blank
  has_and_belongs_to_many :ecochronological_units
  accepts_nested_attributes_for :ecochronological_units, reject_if: :all_blank
end
