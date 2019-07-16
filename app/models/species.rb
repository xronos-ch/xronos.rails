class Species < ApplicationRecord
  has_many :arch_objects, inverse_of: :species
end
