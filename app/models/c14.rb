class C14 < ApplicationRecord
  include DataHelper

  has_paper_trail

  validates :bp, :std, presence: true

  belongs_to :sample
  belongs_to :c14_lab
  belongs_to :source_database

  def self.label
    "radiocarbon date"
  end

  def self.icon
    "icons/c14.svg"
  end

  def uncal_age
    unless bp.blank? && std.blank?
      "#{bp}±#{std} BP"
    else
      na_value
    end
  end

  def cal_age
    unless cal_bp.blank? && cal_std.blank?
      "#{cal_bp}±#{cal_std} cal BP"
    else
      na_value
    end
  end
  
end

