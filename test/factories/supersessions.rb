FactoryBot.define do
  factory :supersession do
    superseded    { create(:site) }
    superseded_by { create(:site) }
  end
end
