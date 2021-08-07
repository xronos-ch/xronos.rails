FactoryBot.define do
  
  factory :reference do
    bibtex { Faker::Lorem.paragraph }
    short_ref { Faker::Name.last_name + Faker::Number.between(from: 1900, to: 2020).to_s }
  end
  
end