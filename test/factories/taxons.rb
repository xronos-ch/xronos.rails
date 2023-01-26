# == Schema Information
#
# Table name: taxons
#
#  id            :bigint           not null, primary key
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_taxons_on_name           (name)
#  index_taxons_on_superseded_by  (superseded_by)
#
FactoryBot.define do
  
  factory :taxon do
    name { Faker::Creature::Animal.unique.name }
  end
  
end
