# == Schema Information
#
# Table name: sources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  access_date   :date
#  file_manifest :jsonb
#  license       :string
#  name          :string           not null
#  notes         :text
#  path          :text
#  source_url    :string
#  version       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_sources_on_name_and_version  (name,version) UNIQUE WHERE (version IS NOT NULL)
#
FactoryBot.define do
  factory :source do
    name { Faker::App.unique.name.parameterize }
    version { "v1" }
    path { "data/sources/#{name}/#{version}" }
    source_url { Faker::Internet.url }
    access_date { Date.current }
    license { "CC-BY 4.0" }

    trait :api do
      version { nil }
      path { nil }
      source_url { "https://api.example.org/v1/dataset" }
      file_manifest { {} }
    end
  end
end
