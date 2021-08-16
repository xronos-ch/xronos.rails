FactoryBot.define do

  factory :fell_phase do
    name { Faker::Barcode.ean }
    start_time {Faker::Number.between(from: 3000, to: 4000)}
    end_time {Faker::Number.between(from: 1000, to: 2000)}
    site
    references { [association(:reference)] }
    
  end
end
