# == Schema Information
#
# Table name: sites
#
#  id            :integer          not null, primary key
#  name          :string
#  lat           :decimal(, )
#  lng           :decimal(, )
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  country_code  :string
#  superseded_by :integer
#
# Indexes
#
#  index_sites_on_country_code  (country_code)
#  index_sites_on_name          (name)
#

FactoryBot.define do
  
  factory :site do
    name { Faker::Verb.unique.base }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    country_code { Faker::Address.country_code }
    
    after(:create) {|site| site.site_types = [create(:site_type)]}

  end
  
end
