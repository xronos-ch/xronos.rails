# == Schema Information
#
# Table name: functional_classification_confidences
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  rank        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :functional_classification_confidence do
    name { "MyString" }
    rank { 1 }
    description { "MyText" }
  end
end
