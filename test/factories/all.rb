FactoryBot.define do
  factory :country do
    name { Faker::String.random(length: 3..12) }
  end
end

FactoryBot.define do
  factory :site do
    name { Faker::String.random(length: 3..12) }
    lat { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    lon { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    country
  end
end
