# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE)
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@xronos.ch" }
    password { "Hubsch123123" }
    password_confirmation { "Hubsch123123" }
    admin { false }
    passphrase { ENV["REGISTRATION_PASSPHRASE"] }
    
    trait :admin do
      sequence(:email) { |n| Faker::Internet.unique.email(name: "admin#{n}", domain: "xronos.ch") }
      admin { true }
    end    
    
    factory :admin, traits: [:admin]
    
    after(:build) do |user|
      user.user_profile ||= build(:user_profile, user: user)
    end
  end
end
