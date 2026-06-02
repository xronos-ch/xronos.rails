# == Schema Information
#
# Table name: data_views
#
#  id                      :integer
#  labnr                   :string
#  bp                      :integer
#  std                     :integer
#  cal_bp                  :integer
#  cal_std                 :integer
#  delta_c13               :float
#  source_database         :text
#  lab_name                :text
#  material                :string
#  species                 :string
#  feature                 :string
#  feature_type            :string
#  site                    :string
#  country                 :string
#  lat                     :text
#  lng                     :text
#  site_type               :string
#  periods                 :jsonb
#  typochronological_units :jsonb
#  ecochronological_units  :jsonb
#  reference               :jsonb
#
# Indexes
#
#  index_data_views_on_country    (country)
#  index_data_views_on_feature    (feature)
#  index_data_views_on_id         (id)
#  index_data_views_on_labnr      (labnr)
#  index_data_views_on_material   (material)
#  index_data_views_on_site       (site)
#  index_data_views_on_site_type  (site_type)
#  index_data_views_on_species    (species)
#

require 'rails_helper'

RSpec.describe DataView, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
