# == Schema Information
#
# Table name: articles
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  body               :text
#  publish            :boolean          default(FALSE)
#  published_at       :datetime
#  section            :integer          not null
#  slug               :string
#  splash_attribution :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_articles_on_section  (section)
#  index_articles_on_slug     (slug) UNIQUE
#  index_articles_on_user_id  (user_id)
#
FactoryBot.define do
  factory :article do
    section { "news" }

    title { Faker::Lorem.sentence(word_count: 5) }

    body do
      Faker::Lorem.paragraphs(number: 2).join("\n\n")
    end

    sequence(:slug) { |n| "article-#{n}" }

    association :user

    publish { false }
    published_at { nil }

    trait :about do
      section { "about" }
      title { "About #{Faker::Lorem.unique.word.capitalize}" }
      body do
        Faker::Lorem.paragraphs(number: 4).join("\n\n")
      end

      sequence(:slug) { |n| "about-page-#{n}" }
    end

    trait :news do
      section { "news" }
    end

    trait :draft do
      publish { false }
      published_at { nil }
    end

    trait :published do
      publish { true }
      published_at { Time.zone.now - rand(1..7).days }
    end

    trait :recently_published do
      publish { true }
      published_at { Time.zone.now - rand(1..24).hours }
    end

    trait :old_published do
      publish { true }
      published_at { Time.zone.now - rand(3..12).months }
    end

    trait :scheduled do
      publish { true }
      published_at { Time.zone.now + rand(1..14).days }
    end

    trait :long_body do
      body do
        Faker::Lorem.paragraphs(number: 8).join("\n\n")
      end
    end

    trait :short_body do
      body { Faker::Lorem.sentence }
    end

    trait :no_body do
      body { nil }
    end

    trait :unpublished_but_dated do
      publish { false }
      published_at { Time.zone.now - 1.day }
    end

  end
end
