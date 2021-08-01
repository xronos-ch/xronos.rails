FactoryBot.define do
  
  factory :species do
    name { Faker::Creature::Animal.unique.name }
  end
  
end