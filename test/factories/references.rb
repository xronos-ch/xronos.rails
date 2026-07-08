FactoryBot.define do
  factory :reference do
    bibtex { Faker::Lorem.paragraph }
    short_ref { Faker::Name.last_name + Faker::Number.between(from: 1900, to: 2020).to_s }

    trait :superseded_by do
      transient do
        canonical { nil }
      end

      after(:create) do |reference, evaluator|
        target = evaluator.canonical || create(:reference)
        create(:supersession, superseded: reference, superseded_by: target)
      end
    end
  end

end
