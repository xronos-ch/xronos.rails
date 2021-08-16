class C14Measurement < ApplicationRecord
  
  has_paper_trail
  
  validates :bp, :std, presence: true

  belongs_to :source_database
  accepts_nested_attributes_for :source_database, reject_if: :all_blank
  validates_associated :source_database
  
  has_one :measurement

end
