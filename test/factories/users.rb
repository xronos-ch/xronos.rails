FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "Hubsch123123" }
    password_confirmation { "Hubsch123123" }
    admin { false }
    passphrase { ENV["REGISTRATION_PASSPHRASE"] }
    trait :admin do
      email { "admin@xronos.ch" }
      admin { true }
    end
    factory :admin, traits: [:admin]
  end
  
end
