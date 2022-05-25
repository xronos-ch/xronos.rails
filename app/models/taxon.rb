class Taxon < ApplicationRecord
  default_scope { order(name: :asc) }
  validates :name, presence: true

  has_many :samples
end
