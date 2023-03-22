# == Schema Information
#
# Table name: contexts
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  superseded_by     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_id           :integer
#
# Indexes
#
#  index_contexts_on_name           (name)
#  index_contexts_on_site_id        (site_id)
#  index_contexts_on_superseded_by  (superseded_by)
#
FactoryBot.define do
  
  factory :context do
    name { Faker::Tea.unique.variety }
    approx_start_time {Faker::Number.between(from: 3000, to: 4000)}
    approx_end_time {Faker::Number.between(from: 1000, to: 2000)}
    site
  end
  
end
