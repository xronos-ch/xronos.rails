class Period < ApplicationRecord
  validates :name, presence: true
  has_and_belongs_to_many :site_phases
  belongs_to :parent, class_name: "Period", optional: true
  has_many :children, class_name: "Period", foreign_key: "parent_id"
  belongs_to :user
end
