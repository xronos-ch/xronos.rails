class FellPhase < ApplicationRecord

  belongs_to :site
  
  belongs_to :user

  has_and_belongs_to_many :references
  accepts_nested_attributes_for :references, reject_if: :all_blank
  validates_associated :references

end
