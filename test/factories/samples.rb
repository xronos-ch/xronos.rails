# == Schema Information
#
# Table name: samples
#
#  id                   :bigint           not null, primary key
#  position_crs         :text
#  position_description :text
#  position_x           :decimal(, )
#  position_y           :decimal(, )
#  position_z           :decimal(, )
#  superseded_by        :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  context_id           :integer
#  material_id          :integer
#  taxon_id             :integer
#
# Indexes
#
#  index_samples_on_context_id     (context_id)
#  index_samples_on_material_id    (material_id)
#  index_samples_on_position_crs   (position_crs)
#  index_samples_on_superseded_by  (superseded_by)
#  index_samples_on_taxon_id       (taxon_id)
#
FactoryBot.define do
  
  factory :sample do
    material
    taxon
    context
    position_description { Faker::Quotes::Shakespeare.hamlet_quote }
    position_x { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_y { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_z { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    position_crs { Faker::Number.number(digits: 5) }
  end
  
end
