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

FactoryBot.define do
  factory :cal do
    type { 0 }
    taq { 9000 }
    median { 9500 }
    tpq { 8000 }
    prob_dist { "" }
  end
end
