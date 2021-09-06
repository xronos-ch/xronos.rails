class C14Measurement < ApplicationRecord

  has_paper_trail

  validates :bp, :std, presence: true

  belongs_to :source_database
  accepts_nested_attributes_for :source_database, reject_if: :all_blank
  validates_associated :source_database

  has_one :measurement

  def uncalibrated_to_setence
    unless bp.blank? && std.blank?
      "Uncalibrated: " +
        bp.to_s + "±" + std.to_s
    end
  end
  
  def calibrated_to_setence
    unless cal_bp.blank? && cal_std.blank?
      "Calibrated: " +
        cal_bp.to_s + "±" + cal_std.to_s
    end
  end

end

