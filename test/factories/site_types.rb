FactoryBot.define do
  
  factory :site_type do
    name { Faker::Name.unique.last_name }
    description { Faker::Lorem.sentence }
  end
  
end