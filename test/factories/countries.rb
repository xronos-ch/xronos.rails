FactoryBot.define do
  
  factory :country do
    name { Faker::Address.unique.country }
  end
end