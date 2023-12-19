# == Schema Information
#
# Table name: taxons
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  gbif_id    :integer
#
# Indexes
#
#  index_taxons_on_gbif_id  (gbif_id)
#  index_taxons_on_name     (name)
#
FactoryBot.define do
  
  factory :taxon do
    name { Faker::Creature::Animal.unique.name }
  end
  
end
