FactoryBot.define do
  
  factory :ecochronological_unit do
    name { Faker::Space.unique.meteorite }
    approx_start_time {Faker::Number.between(from: 3000, to: 4000)}
    approx_end_time {Faker::Number.between(from: 1000, to: 2000)}
  end
  
end