FactoryBot.define do
  
  factory :source_database do
    name { Faker::Company.unique.name }
    url { Faker::Internet.url }
    citation { Faker::Book.title }
    licence { Faker::DrivingLicence.british_driving_licence }
  end
  
end