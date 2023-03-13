class SiteType < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } } # match partial words

  validates :name, presence: true
  has_many :sites, inverse_of: :site_type

  acts_as_copy_target # enable CSV exports
end
