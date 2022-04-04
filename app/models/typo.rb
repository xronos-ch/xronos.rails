class Typo < ApplicationRecord
  include DataHelper
  
  has_paper_trail

  validates :name, presence: true
  
  belongs_to :sample

  # Internal heirarchy
  belongs_to :parent, class_name: "Typo", optional: true
  has_many :children, class_name: "Typo", foreign_key: "typo_id"

  def self.label
    "typological date"
  end

  def age
    unless approx_start_time.blank? && approx_end_time.blank?
      "#{approx_start_time}–#{approx_end_time}"
    else
      na_value
    end
  end
end
