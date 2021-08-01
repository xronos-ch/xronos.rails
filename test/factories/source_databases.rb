FactoryBot.define do
  
  factory :source_database do
    name { Faker::Company.unique.name }
  end
  
end