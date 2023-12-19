# == Schema Information
#
# Table name: sites
#
#  id            :bigint           not null, primary key
#  country_code  :string
#  lat           :decimal(, )
#  lng           :decimal(, )
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
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
