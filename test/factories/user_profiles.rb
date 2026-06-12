# == Schema Information
#
# Table name: user_profiles
# Database name: primary
#
#  id           :bigint           not null, primary key
#  affiliation  :text
#  full_name    :string
#  orcid        :string
#  public_email :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_profile do
    association :user

    full_name { "Test User" }

    sequence(:orcid) { |n| format("0000-0000-0000-%04d", n) }

    public_email { user.email }

    url { "https://example.com/profile" }

    # --- Traits ---

    trait :with_realistic_name do
      sequence(:full_name) { |n| "User #{n}" }
    end

    trait :with_affiliation do
      affiliation { "University of Bern" }
    end

    trait :with_orcid do
      # already default, but kept for clarity/override
    end

    trait :without_orcid do
      orcid { nil }
    end

    trait :custom_email do
      sequence(:public_email) { |n| "public#{n}@example.com" }
    end

    trait :no_public_email do
      public_email { nil }
    end

    trait :with_url do
      sequence(:url) { |n| "https://example.com/users/#{n}" }
    end

    trait :no_url do
      url { nil }
    end

    trait :complete do
      with_realistic_name
      with_url
    end
  end
end

