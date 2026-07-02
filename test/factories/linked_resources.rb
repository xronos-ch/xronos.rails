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
#  index_linked_resources_on_linkable_and_source            (linkable_type,linkable_id,source) UNIQUE
#  index_linked_resources_on_linkable_type_and_linkable_id  (linkable_type,linkable_id)
#
FactoryBot.define do
  factory :linked_resource do
    association :linkable, factory: :site
    source { 'Wikidata' }
    external_id { FactoryBot.external_id_for(source) }
  end
end
