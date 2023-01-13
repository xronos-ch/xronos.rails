class C14 < ApplicationRecord
  include DataHelper

  include PgSearch::Model
  pg_search_scope :search, 
    against: :lab_identifier, 
    using: { tsearch: { prefix: true } } # match partial words

  has_paper_trail
  acts_as_copy_target # enable CSV exports

  validates :bp, :std, presence: true

  belongs_to :sample
  accepts_nested_attributes_for :sample, reject_if: :all_blank
  validates_associated :sample

  has_one :context, :through => :sample
  has_one :site, :through => :context

  belongs_to :c14_lab, optional: true
  belongs_to :source_database, optional: true

  has_many :citations, as: :citing
  has_many :references, :through => :citations

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
      nil
    end
  end

  def cal_age
    unless cal_bp.blank? && cal_std.blank?
      "#{cal_bp}±#{cal_std} cal BP"
    else
      nil
    end
  end
  
end

