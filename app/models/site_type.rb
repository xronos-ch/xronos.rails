class SiteType < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } } # match partial words

  has_many :sites, inverse_of: :site_type
  has_paper_trail

  validates :name, presence: true

end
