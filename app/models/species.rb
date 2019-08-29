class Species < ApplicationRecord
  validates :name, presence: true

  has_many :arch_objects
end
