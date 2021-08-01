FactoryBot.define do
  
  factory :material do
    name { Faker::Construction.unique.material }
  end
  
end