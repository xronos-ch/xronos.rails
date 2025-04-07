# == Schema Information
#
# Table name: c14_labs
#
#  id           :bigint           not null, primary key
#  active       :boolean
#  country_code :string
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_c14_labs_on_active  (active)
#  index_c14_labs_on_name    (name)
#
FactoryBot.define do
  
  factory :c14_lab do
    name { Faker::Address.city }
    country_code { Faker::Address.country_code }
    active { [true, false].sample }
    after :create do |c14_lab|
      create_list :c14_lab_code, 1, c14_lab: c14_lab, canonical: true
      create_list :c14_lab_code, 2, c14_lab: c14_lab, canonical: false
    end
  end
  
end
