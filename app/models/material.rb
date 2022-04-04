class Material < ApplicationRecord
  has_many :samples, inverse_of: :material
  validates :name, presence: true
end
