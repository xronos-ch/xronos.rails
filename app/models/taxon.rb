class Taxon < ApplicationRecord
  validates :name, presence: true

  has_many :samples
end
