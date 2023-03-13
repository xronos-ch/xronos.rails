class Typo < ApplicationRecord
  include DataHelper
  
  has_paper_trail
  acts_as_copy_target # enable CSV exports

  validates :name, presence: true
  
  belongs_to :sample
  delegate :context, to: :sample
  delegate :site, to: :context

  has_many :citations, as: :citing
  has_many :references, through: :citations

  # Internal heirarchy
  belongs_to :parent, class_name: "Typo", optional: true
  has_many :children, class_name: "Typo", foreign_key: "typo_id"

  acts_as_copy_target # enable CSV exports

  def self.label
    "typological date"
  end

  def self.icon
    "icons/typo.svg"
  end

  def age
    return nil if approx_start_time.blank? && approx_end_time.blank?
    
    "#{approx_start_time}–#{approx_end_time}"
  end
end
