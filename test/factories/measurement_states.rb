FactoryBot.define do
  
  factory :measurement_state do
    name { Faker::Name.unique.first_name }
    description { Faker::ChuckNorris.fact }
  end
  
end
