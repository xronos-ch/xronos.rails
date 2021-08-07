FactoryBot.define do
  
  factory :site do
    name { Faker::Verb.unique.base }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    country
  end
  
end