FactoryBot.define do
  factory :lod_link do
    association :linkable, factory: :site
    source { "Wikidata" }
    external_id { Faker::Number.number(digits: 6) }
  end
end
