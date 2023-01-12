FactoryBot.define do
  
  factory :sample do
    material
    taxon
    context
    position_description { Faker::Quotes::Shakespeare.hamlet_quote }
    position_x { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_y { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_z { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_crs { Faker::Number.number(digits: 5) }
  end
  
end