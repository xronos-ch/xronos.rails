FactoryBot.define do

  factory :typo do
    association :sample
    sequence(:name) { |n| "Typological unit #{n}" }

    trait :superseded_by do
      transient do
        canonical { nil }
      end

      after(:create) do |typo, evaluator|
        target = evaluator.canonical || create(:typo, sample: typo.sample)
        create(:supersession, superseded: typo, superseded_by: target)
      end
    end

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
