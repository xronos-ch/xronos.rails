# == Schema Information
#
# Table name: contexts
#
#  id                :integer          not null, primary key
#  name              :string
#  approx_start_time :integer
#  approx_end_time   :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_id           :integer
#
# Indexes
#
#  index_contexts_on_name     (name)
#  index_contexts_on_site_id  (site_id)
#

FactoryBot.define do
  
  factory :context do
    name { Faker::Tea.unique.variety }
    approx_start_time {Faker::Number.between(from: 3000, to: 4000)}
    approx_end_time {Faker::Number.between(from: 1000, to: 2000)}
    site
  end
  
end
