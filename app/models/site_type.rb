class SiteType < ApplicationRecord
  default_scope { order(name: :asc) }

  validates :name, presence: true
  has_many :sites, inverse_of: :site_type
end
