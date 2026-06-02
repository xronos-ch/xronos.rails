# == Schema Information
#
# Table name: functional_classification_categories
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :functional_classification_category do
    name { "MyString" }
    description { "MyText" }
  end
end
