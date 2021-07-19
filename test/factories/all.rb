FactoryBot.define do
  factory :country do
    name { Faker::Verb.unique.base }
  end
end

FactoryBot.define do
  factory :site do
    name { Faker::Verb.unique.base }
    lat { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    lng { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    country
  end
  
  factory :source_database do
    name { Faker::Verb.unique.base }
  end
end

FactoryBot.define do
  factory :c14_measurement do
    bp {Faker::Number.number(digits: 4)}
    std {Faker::Number.number(digits: 4)}
    source_database 
  end
end

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "Hubsch123123" }
    password_confirmation { "Hubsch123123" }
    admin { false }
    passphrase { ENV["REGISTRATION_PASSPHRASE"] }
    trait :admin do
      admin { true }
    end
    factory :admin, traits: [:admin]
  end
end
