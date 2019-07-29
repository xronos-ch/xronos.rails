class SiteType < ApplicationRecord
  validates :name, presence: true
  has_many :site_phases, inverse_of: :site_type
end
