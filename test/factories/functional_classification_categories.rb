# test/factories/functional_classification_categories.rb

FactoryBot.define do
  factory :functional_classification_category do
    sequence(:name) { |n| "Functional category #{n}" }
    description { "Functional classification category used in tests." }
  end
end