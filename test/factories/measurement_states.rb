FactoryBot.define do
  
  factory :measurement_state do
    name { Faker::Emotion.unique.noun }
    description { Faker::Emotion.adjective }
  end
  
end
