FactoryBot.define do
  factory :c14 do
    bp { Faker::Number.number(digits: 4) }
    std { Faker::Number.number(digits: 2) }
    cal_bp { Faker::Number.number(digits: 4) }
    cal_std { Faker::Number.number(digits: 2) }
    delta_c13  { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    delta_c13_std { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
    lab_identifier { "#{ Faker::Address.country_code_long }-#{ Faker::Address.building_number }" }
    add_attribute(:method) {Faker::Hacker.noun}

    c14_lab
    sample

    trait :superseded_by do
      transient do
        canonical { nil }
      end

      after(:create) do |c14, evaluator|
        target = evaluator.canonical || create(:c14, sample: c14.sample)
        create(:supersession, superseded: c14, superseded_by: target)
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
