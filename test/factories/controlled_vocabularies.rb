# == Schema Information
#
# Table name: controlled_vocabularies
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_controlled_vocabularies_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :controlled_vocabulary do
    sequence(:name) { |n| "vocabulary_#{n}" }
    description { "Test controlled vocabulary" }
  end
end
