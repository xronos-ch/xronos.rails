FactoryBot.define do
  
  factory :feature_type do
    name { Faker::Name.unique.last_name }
    description { Faker::Lorem.sentence }
  end
  
end