# == Schema Information
#
# Table name: c14s
#
#  id             :bigint           not null, primary key
#  bp             :integer
#  cal_bp         :integer
#  cal_std        :integer
#  delta_c13      :float
#  delta_c13_std  :float
#  lab_identifier :string
#  method         :string
#  std            :integer
#  superseded_by  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  c14_lab_id     :bigint
#  sample_id      :bigint
#
# Indexes
#
#  index_c14s_on_c14_lab_id      (c14_lab_id)
#  index_c14s_on_lab_identifier  (lab_identifier)
#  index_c14s_on_method          (method)
#  index_c14s_on_sample_id       (sample_id)
#  index_c14s_on_superseded_by   (superseded_by)
#
class C14 < ApplicationRecord
  include DataHelper

  include Versioned
  include Supersedable

  include PgSearch::Model
  pg_search_scope :search, 
    against: :lab_identifier, 
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :lab_identifier

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

