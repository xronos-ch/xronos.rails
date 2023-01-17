class Taxon < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  validates :name, presence: true

  has_many :samples

  has_paper_trail
end
