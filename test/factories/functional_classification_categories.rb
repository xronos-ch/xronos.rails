# test/factories/functional_classification_categories.rb

# == Schema Information
#
# Table name: functional_classification_categories
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :functional_classification_category do
    sequence(:name) { |n| "Functional category #{n}" }
    description { "Functional classification category used in tests." }
  end
end
