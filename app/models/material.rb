class Material < ApplicationRecord
  has_many :arch_objects, inverse_of: :material
  validates :name, presence: true
end
