# test/factories/functional_classifications.rb

FactoryBot.define do
  factory :functional_classification do
    association :assignable, factory: :context
    association :functional_classification_category
    confidence { :possible }
    source { "Test source" }
    note { "Test note" }
  end
end