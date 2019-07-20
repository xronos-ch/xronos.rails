class SitePhase < ApplicationRecord
  has_and_belongs_to_many :periods
  has_and_belongs_to_many :ecochronological_units
  has_and_belongs_to_many :typochronological_units
end
