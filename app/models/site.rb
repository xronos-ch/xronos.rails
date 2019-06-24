class Site < ApplicationRecord
  has_many :physical_locations
  has_many :countries, :through => :physical_locations
  belongs_to :site_type
end
