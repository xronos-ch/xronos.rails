class Country < ApplicationRecord
  has_many :physical_locations
  has_many :sites, :through => :physical_locations
end
