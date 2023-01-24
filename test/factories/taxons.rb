FactoryBot.define do
  
  factory :taxon do
    name { Faker::Creature::Animal.unique.name }
  end
  
end