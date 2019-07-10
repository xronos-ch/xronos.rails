class Site < ApplicationRecord
  has_many :arch_objects, inverse_of: :site
  belongs_to :country
  belongs_to :site_type
end
