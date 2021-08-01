FactoryBot.define do
  
  factory :material do
    sequence(:name)   { |n| "Material #{n}" }
  end
  
end