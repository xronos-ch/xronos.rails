class TypochronologicalUnit < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :site_phases
  belongs_to :parent, class_name: "TypochronologicalUnit"
  has_many :children, class_name: "TypochronologicalUnit", foreign_key: "parent_id"
end
