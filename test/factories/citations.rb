FactoryBot.define do
  factory :citation do
    association :reference
    association :citing, factory: :site
  end
end

