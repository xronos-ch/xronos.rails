class Site < ApplicationRecord
  has_paper_trail
  
  validates :name, presence: true

  has_many :site_phases, inverse_of: :site

  belongs_to :country, optional: true
  accepts_nested_attributes_for :country, reject_if: :all_blank, allow_destroy: true
  validates_associated :country

  has_many :fell_phases, inverse_of: :site
  accepts_nested_attributes_for :fell_phases, reject_if: :all_blank, allow_destroy: true
  validates_associated :fell_phases
  
  has_many :measurements, through: :site_phases

end
