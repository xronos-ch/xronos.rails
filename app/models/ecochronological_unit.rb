class EcochronologicalUnit < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :site_phases
  belongs_to :parent, class_name: "EcochronologicalUnit", optional: true
  has_many :children, class_name: "EcochronologicalUnit", foreign_key: "parent_id"
end
