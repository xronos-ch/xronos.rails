FactoryBot.define do
  
  factory :c14_lab do
    name { Faker::Address.city }
    active { [true, false].sample }
  end
  
end