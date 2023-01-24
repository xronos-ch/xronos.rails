FactoryBot.define do
  
  factory :c14 do
    bp { Faker::Number.number(digits: 4) }
    std { Faker::Number.number(digits: 2) }
    cal_bp { Faker::Number.number(digits: 4) }
    cal_std { Faker::Number.number(digits: 2) }
    delta_c13  { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    delta_c13_std { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
    lab_identifier { "#{ Faker::Address.country_code_long }-#{ Faker::Address.building_number }" }
    add_attribute(:method) {Faker::Hacker.noun}
    
    source_database
    c14_lab
    sample
  end
  
end