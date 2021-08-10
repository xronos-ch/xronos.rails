FactoryBot.define do
  
  factory :measurment_state do
    name { Faker::Emotion.unique.noun }
    description { Faker::Emotion.adjective }
  end
  
end
