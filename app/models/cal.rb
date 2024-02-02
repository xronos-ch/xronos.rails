##
# Summaries for probabilistic calendar ages. Specific types of distribution,
# e.g. calibrated radiocarbon dates or uniform period estimates are represented
# by subclasses. All calendric fields are implicitly whole years BP.
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
class Cal < ApplicationRecord

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

  def range
    [ taq, tpq ]
  end

end
