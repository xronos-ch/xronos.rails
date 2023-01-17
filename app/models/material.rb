class Material < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  has_many :samples, inverse_of: :material
  has_paper_trail

  validates :name, presence: true
end
