FactoryBot.define do
  
  factory :site_phase do
    name { Faker::Tea.unique.variety }
    approx_start_time {Faker::Number.between(from: 3000, to: 4000)}
    approx_end_time {Faker::Number.between(from: 1000, to: 2000)}
    site
    site_type
  end
  
end