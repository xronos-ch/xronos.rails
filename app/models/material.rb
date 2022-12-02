class Material < ApplicationRecord
  default_scope { order(name: :asc) }

  has_many :samples, inverse_of: :material
  validates :name, presence: true
end
