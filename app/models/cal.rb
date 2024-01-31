##
# Cal class
#
# Represents probabilistic calendar ages, e.g. calibrated radiocarbon dates or
# period estimates. All time fields are implicitly whole years BP.
#
# == Schema Information
#
# Table name: cals
#
#  id         :bigint           not null, primary key
#  c14_age    :integer
#  c14_curve  :integer
#  c14_error  :integer
#  median     :integer
#  prob_dist  :jsonb            not null
#  source     :integer          not null
#  taq        :integer
#  tpq        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cals_on_source                                          (source)
#  index_cals_on_source_and_c14_age_and_c14_error_and_c14_curve  (source,c14_age,c14_error,c14_curve) UNIQUE
#
class Cal < ApplicationRecord
  enum :source, { assertion: 0, calibration: 1 }
  enum :c14_curve, { IntCal20: 0, SHCal20: 1, Marine20: 2 }

  before_validation :recalibrate, on: [ :create, :update ], if: :calibration?

  validates :source, presence: true
  validates :prob_dist, presence: true

  # Validate taq >= median >= tpq
  validates :taq, 
    presence: true, 
    comparison: { greater_than_or_equal_to: :tpq }
  validates :median, 
    presence: true,
    comparison: { less_than_or_equal_to: :taq, greater_than_or_equal_to: :tpq }
  validates :tpq, 
    presence: true,
    comparison: { less_than_or_equal_to: :taq }

  # Validate unique combination of c14_age, c14_error, and c14_curve (for
  # calibrations)
  validates :c14_age, 
    presence: true, 
    uniqueness: { scope: [ :c14_error, :c14_curve ] },
    if: :calibration?
  validates :c14_error, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_curve ] },
    if: :calibration?
  validates :c14_curve, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_error ] },
    if: :calibration?

  def recalibrate
    return nil unless c14_age.present? && c14_error.present? && c14_curve.present?
    calibration = Calibrator::Calibration.new(c14_age, c14_error, c14_curve)
    
    self.prob_dist = calibration.prob_dist
    self.taq = calibration.hd_intervals.map { |i| i["begin"] }.max
    self.tpq = calibration.hd_intervals.map { |i| i["end"] }.min
    # TODO: terrible, but currently unused, so...
    self.median = self.tpq + ((self.taq - self.tpq) / 2)
  end

  def range
    [ taq, tpq ]
  end

  def hd_intervals(interval = 0.954)
    # TODO: support different values of sigma: https://github.com/xronos-ch/xronos.rails/issues/327
    # TODO: avoid call to calibrator: https://github.com/xronos-ch/xronos.rails/issues/329
    return nil unless c14_age.present? && c14_error.present? && c14_curve.present?
    calibration = Calibrator::Calibration.new(c14_age, c14_error, c14_curve)
    calibration.hd_intervals
  end

end
