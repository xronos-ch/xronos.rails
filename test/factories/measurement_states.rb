# == Schema Information
#
# Table name: measurement_states
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_measurement_states_on_name  (name)
#
FactoryBot.define do
  
  factory :measurement_state do
    name { Faker::Name.unique.first_name }
    description { Faker::ChuckNorris.fact }
  end
  
end
