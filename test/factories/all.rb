FactoryBot.define do
  factory :country do
    name { Faker::TvShows::Stargate.planet }
  end
end

FactoryBot.define do
  factory :site do
    name { Faker::TvShows::Stargate.planet }
    lat { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    lng { Faker::Number.decimal(l_digits: 2, r_digits: 4) }
    country
  end
end

FactoryBot.define do
  factory :user do
    email { "test@test.com" }
    password { "Hubsch123123" }
    password_confirmation { "Hubsch123123" }
    admin { true }
    passphrase { ENV["REGISTRATION_PASSPHRASE"] }
  end
end
