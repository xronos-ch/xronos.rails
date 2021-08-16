class Sample < ApplicationRecord
  has_paper_trail
  
  has_many :measurements, inverse_of: :sample, :dependent => :destroy
  accepts_nested_attributes_for :measurements, reject_if: :all_blank, allow_destroy: true
  validates_associated :measurements
  belongs_to :arch_object
end
