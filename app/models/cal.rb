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
  enum source, [ :assertion, :calibration ], suffix: true
  enum curve, [ :intcal20, :shcal20, :marine20 ]

  validates :type, presence: true
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
    if: calibration?
  validates :c14_error, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_curve ] },
    if: calibration?
  validates :c14_curve, 
    presence: true, 
    uniqueness: { scope: [ :c14_age, :c14_error ] },
    if: calibration?
end
