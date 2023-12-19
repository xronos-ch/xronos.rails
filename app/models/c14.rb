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
#
class C14 < ApplicationRecord

  belongs_to :sample
  accepts_nested_attributes_for :sample, reject_if: :all_blank

  belongs_to :c14_lab, optional: true
  belongs_to :source_database, optional: true

  has_many :citations, as: :citing
  has_many :references, :through => :citations

  delegate :context, to: :sample
  delegate :site, to: :sample

  validates :bp, :std, presence: true
  validates_associated :sample

  composed_of :lab_id, mapping: %w(lab_identifier), allow_nil: true

  include Versioned

  include HasIssues
  @issues = [ :missing_c14_age, :very_old_c14, :missing_c14_error, 
              :missing_d13c, :missing_d13c_error, :missing_c14_method, 
              :missing_c14_lab_id, :invalid_lab_id, :missing_c14_lab ]

  include PgSearch::Model
  pg_search_scope :search, 
    against: :lab_identifier, 
    using: { tsearch: { prefix: true } } # match partial words
  multisearchable against: :lab_identifier

  acts_as_copy_target # enable CSV exports

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

  # Issues
  
  scope :missing_c14_age, -> { where(bp: nil) }
  def missing_c14_age?
    bp.blank?
  end

  scope :very_old_c14, -> { where("bp > 50000") }
  def very_old_c14?
    return nil if bp.blank?
    bp > 50000
  end

  scope :missing_c14_error, -> { where(std: nil) }
  def missing_c14_error?
    std.blank?
  end

  scope :missing_d13c, -> { where(delta_c13: nil) }
  def missing_d13c?
    delta_c13.blank?
  end

  scope :missing_d13c_error, -> { where(delta_c13_std: nil) }
  def missing_d13c_error?
    delta_c13_std.blank?
  end
  
  scope :missing_c14_method, -> { where(method: nil) }
  def missing_c14_method?
    method.blank?
  end
  
  scope :missing_c14_lab_id, -> { where(lab_identifier: nil) }
  def missing_c14_lab_id?
    lab_identifier.blank?
  end

  scope :invalid_lab_id, -> { where("lab_identifier !~* ?", LabId::PATTERN) }
  def invalid_lab_id?
    return false if lab_id.blank?
    lab_id.invalid?
  end
  
  scope :missing_c14_lab, -> { where(c14_lab_id: nil) }
  def missing_c14_lab?
    c14_lab_id.blank?
  end
  
end

