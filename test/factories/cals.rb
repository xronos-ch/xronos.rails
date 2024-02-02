# == Schema Information
#
# Table name: cals
#
#  id         :bigint           not null, primary key
#  c14_age    :integer
#  c14_curve  :integer
#  c14_error  :integer
#  centre     :integer
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
FactoryBot.define do
  factory :cal do
    type { 0 }
    taq { 9000 }
    median { 9500 }
    tpq { 8000 }
    prob_dist { "" }
  end
end
