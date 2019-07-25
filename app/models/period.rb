class Period < ApplicationRecord
  has_and_belongs_to_many :site_phases
  validates :name, presence: true
end
