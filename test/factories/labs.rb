FactoryBot.define do
  
  factory :lab do
    name { Faker::Address.unique.city }
    active { [true, false].sample }
  end
  
end