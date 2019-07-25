class Site < ApplicationRecord
  validates :name, presence: true
  has_many :site_phases, inverse_of: :site
  belongs_to :country, optional: true
  accepts_nested_attributes_for :country, reject_if: :all_blank, allow_destroy: true
  validates_associated :country
  belongs_to :site_type, optional: true
  accepts_nested_attributes_for :site_type, reject_if: :all_blank, allow_destroy: true
  validates_associated :site_type
end
