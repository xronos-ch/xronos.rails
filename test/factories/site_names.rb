FactoryBot.define do
  factory :site_name do
    association :site
    sequence(:name) { |n| "Alternative site name #{n}" }
  end
end
