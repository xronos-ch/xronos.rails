class Material < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  has_many :samples, inverse_of: :material
  validates :name, presence: true

  acts_as_copy_target # enable CSV exports
end
