# == Schema Information
#
# Table name: c14_labs
#
#  id           :bigint           not null, primary key
#  active       :boolean
#  city         :string
#  country_code :string
#  name         :string
#  short_name   :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  successor_id :bigint
#
# Indexes
#
#  index_c14_labs_on_active        (active)
#  index_c14_labs_on_name          (name)
#  index_c14_labs_on_short_name    (short_name) UNIQUE
#  index_c14_labs_on_successor_id  (successor_id)
#
# Foreign Keys
#
#  fk_rails_...  (successor_id => c14_labs.id)
#
FactoryBot.define do
  
  factory :c14_lab do
    city { Faker::Address.unique.city }
    name { city + " Radiocarbon Laboratory" }
    short_name { city + " Lab" }
    country_code { Faker::Address.country_code }
    url { Faker::Internet.url }
    active { [true, false].sample }
    # TODO: successor for inactive labs?
    after :create do |c14_lab|
      create_list :c14_lab_code, 1, c14_lab: c14_lab, canonical: true
      create_list :c14_lab_code, 2, c14_lab: c14_lab, canonical: false
    end
  end
  
end
