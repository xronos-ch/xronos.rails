##
# Summaries for probabilistic calendar ages. Specific types of distribution,
# e.g. calibrated radiocarbon dates or uniform period estimates are represented
# by subclasses. All calendric fields are implicitly whole years BP.
#
# == Schema Information
#
# Table name: cals
#
#  id         :integer          not null, primary key
#  c14_age    :integer
#  c14_error  :integer
#  c14_curve  :integer
#  taq        :integer
#  centre     :integer
#  tpq        :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string           not null
#
# Indexes
#
#  index_cals_on_type_and_c14_age_and_c14_error_and_c14_curve  (type,c14_age,c14_error,c14_curve) UNIQUE
#

class Cal < ApplicationRecord

  validates :type, presence: true
  validates :prob_dist, presence: true

  # Validate taq >= centre >= tpq
  validates :taq, 
    presence: true, 
    comparison: { greater_than_or_equal_to: :tpq }
  validates :centre, 
    presence: true,
    comparison: { less_than_or_equal_to: :taq, greater_than_or_equal_to: :tpq }
  validates :tpq, 
    presence: true,
    comparison: { less_than_or_equal_to: :taq }

  def range
    if taq.present? && tpq.present?
      [taq, tpq]
    else
      ["can not be calculated"]
    end
  end
end
