class EcochronologicalUnit < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :site_phases
end
