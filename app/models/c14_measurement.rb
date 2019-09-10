class C14Measurement < ApplicationRecord

  validates :bp, :std, :cal_bp, :cal_std, presence: true

  belongs_to :source_database
  accepts_nested_attributes_for :source_database, reject_if: :all_blank
  validates_associated :source_database

end
