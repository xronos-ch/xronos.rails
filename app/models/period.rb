class Period < ApplicationRecord
  has_and_belongs_to_many :site_phases
  validates :name, presence: true
  belongs_to :parent, class_name: "Period"
  has_many :children, class_name: "Period", foreign_key: "parent_id"
end
