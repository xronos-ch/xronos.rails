# == Schema Information
#
# Table name: linked_resources
# Database name: primary
#
#  id            :bigint           not null, primary key
#  data          :jsonb
#  linkable_type :string           not null
#  source        :string           not null
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string           not null
#  linkable_id   :bigint           not null
#
# Indexes
#
#  index_linked_resources_on_linkable_type_and_linkable_id       (linkable_type,linkable_id)
#  index_linked_resources_on_polymorphic_source_and_external_id  (linkable_type,linkable_id,source,external_id) UNIQUE
#
FactoryBot.define do
  factory :linked_resource do
    association :linkable, factory: :site
    source { "Wikidata" }
    external_id { Faker::Number.number(digits: 6) }
  end
end
