# == Schema Information
#
# Table name: materials
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_materials_on_name  (name)
#
FactoryBot.define do
  
  factory :material do
    sequence(:name)   { |n| "Material #{n}" }
  end
  
end
