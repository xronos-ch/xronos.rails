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
FactoryBot.define do
  
  factory :c14 do
    bp { Faker::Number.number(digits: 4) }
    std { Faker::Number.number(digits: 2) }
    cal_bp { Faker::Number.number(digits: 4) }
    cal_std { Faker::Number.number(digits: 2) }
    delta_c13  { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    delta_c13_std { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
    lab_identifier { "#{ Faker::Address.country_code_long }-#{ Faker::Address.building_number }" }
    add_attribute(:method) {Faker::Hacker.noun}
    
    c14_lab
    sample
  end
  
end
