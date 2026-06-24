FactoryBot.define do
  factory :import do
    source
    records_created { { "site" => 5, "c14" => 10 } }
    records_updated { { "site" => 2 } }
    success { true }

    trait :failed do
      success { false }
      error { "Something went wrong" }
    end
  end
end
