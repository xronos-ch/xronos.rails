# == Schema Information
#
# Table name: sites
# Database name: primary
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

    trait :with_site_names do
      transient do
        site_names_count { 2 }
      end

      after(:create) do |site, evaluator|
        create_list(:site_name, evaluator.site_names_count, site: site)
      end
    end

    trait :with_linked_resources do
      transient do
        linked_resources_count { 2 }
      end

      after(:create) do |site, evaluator|
        create_list(:linked_resource, evaluator.linked_resources_count, linkable: site)
      end
    end

    trait :with_citations do
      transient do
        citations_count { 2 }
      end

      after(:create) do |c14, evaluator|
        create_list(:citation, evaluator.citations_count, citing: c14)
      end
    end

  end
  
end
