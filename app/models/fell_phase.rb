class FellPhase < ApplicationRecord

  has_paper_trail
  
  belongs_to :site
  
  has_and_belongs_to_many :references
  accepts_nested_attributes_for :references, reject_if: :all_blank
  validates_associated :references

end
