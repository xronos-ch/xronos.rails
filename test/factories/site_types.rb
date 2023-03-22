# == Schema Information
#
# Table name: site_types
#
#  id            :bigint           not null, primary key
#  description   :text
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_types_on_name           (name)
#  index_site_types_on_superseded_by  (superseded_by)
#
FactoryBot.define do
  
  factory :site_type do
    name { Faker::Name.unique.last_name }
    description { Faker::Lorem.sentence }
  end
  
end
