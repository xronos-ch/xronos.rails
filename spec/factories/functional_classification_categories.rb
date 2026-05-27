# == Schema Information
#
# Table name: functional_classification_categories
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :functional_classification_category do
    name { "MyString" }
    description { "MyText" }
  end
end
