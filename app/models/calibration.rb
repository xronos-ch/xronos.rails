##
# Cal sublass representing calibrated radiocarbon dates.
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
#  taq        :integer
#  tpq        :integer
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cals_on_type_and_c14_age_and_c14_error_and_c14_curve  (type,c14_age,c14_error,c14_curve) UNIQUE
#
class Calibration < Cal
  enum :c14_curve, { IntCal20: 0, SHCal20: 1, Marine20: 2 }

  # Probability distribution. Not persisted.
  attr_accessor :prob_dist
  # Highest density interval(s). Not persisted.
  attr_accessor :hd_intervals
  # TODO: support different values of sigma: https://github.com/xronos-ch/xronos.rails/issues/327

  # Validate unique combination of c14_age, c14_error, and c14_curve
  validates :c14_age, 
    presence: true, 
    uniqueness: { scope: [ :c14_error, :c14_curve ] }
  validates :c14_error, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_curve ] }
  validates :c14_curve, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_error ] }

  before_validation :recalibrate, on: [:create, :update]

  # Calibrate if necessary
  def calibrate
    if prob_dist.blank? and hd_intervals.blank?
      self.recalibrate
    end
  end

  # Force recalibration and update all attributes accordingly
  def recalibrate
    return nil unless c14_age.present? && c14_error.present? && c14_curve.present?

    logger.info "Calibrating #{{ c14_age: c14_age, c14_error: c14_error, c14_curve: c14_curve}}"
    calibration = Calibrator::Calibration.new(c14_age, c14_error, c14_curve)
    
    self.taq = calibration.hd_intervals.map { |i| i["begin"] }.max
    self.tpq = calibration.hd_intervals.map { |i| i["end"] }.min
    # TODO: terrible, but currently unused, so...
    self.median = self.tpq + ((self.taq - self.tpq) / 2)

    # Not persisted
    self.prob_dist = calibration.prob_dist
    self.hd_intervals = calibration.hd_intervals
  end

end
