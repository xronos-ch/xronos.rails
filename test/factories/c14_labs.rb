# == Schema Information
#
# Table name: c14_labs
#
#  id            :bigint           not null, primary key
#  active        :boolean
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_c14_labs_on_active         (active)
#  index_c14_labs_on_name           (name)
#  index_c14_labs_on_superseded_by  (superseded_by)
#
FactoryBot.define do
  
  factory :c14_lab do
    name { Faker::Address.city }
    active { [true, false].sample }
  end
  
end
