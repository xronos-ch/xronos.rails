FactoryBot.define do

  factory :typo do
    association :sample
    sequence(:name) { |n| "Typological unit #{n}" }

    trait :with_citations do
      transient do
        citations_count { 2 }
      end

      after(:create) do |c14, evaluator|
        create_list(:citation, evaluator.citations_count, citing: c14)
      end
    end

  end

end
