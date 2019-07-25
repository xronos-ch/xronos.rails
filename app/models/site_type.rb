class SiteType < ApplicationRecord
  validates :name, presence: true
  has_many :sites, inverse_of: :site
end
