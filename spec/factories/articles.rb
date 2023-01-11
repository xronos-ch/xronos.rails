FactoryBot.define do
  factory :article do
    section { "" }
    slug { "" }
    title { "" }
    user { "" }
    published_at { "2023-01-10 14:30:31" }
    body { "MyText" }
  end
end
