FactoryBot.define do
  factory :source do
    name { Faker::App.unique.name.parameterize }
    version { "v1" }
    path { "data/sources/#{name}/#{version}" }
    source_url { Faker::Internet.url }
    access_date { Date.current }
    license { "CC-BY 4.0" }

    trait :api do
      version { nil }
      path { nil }
      source_url { "https://api.example.org/v1/dataset" }
      file_manifest { {} }
    end
  end
end
