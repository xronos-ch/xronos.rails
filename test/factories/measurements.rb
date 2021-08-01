FactoryBot.define do
  
  factory :measurement do
    labnr { Faker::Alphanumeric.alpha(number: 3) + "-" + Faker::Number.number(digits:5).to_s }
    sample
    lab
    trait :is_14c do
      c14_measurement
    end
  end
  
end