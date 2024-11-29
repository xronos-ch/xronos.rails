# == Schema Information
#
# Table name: data_views
#
#  id                      :bigint
#  bp                      :integer
#  cal_bp                  :integer
#  cal_std                 :integer
#  country                 :string
#  delta_c13               :float
#  ecochronological_units  :jsonb
#  feature                 :string
#  feature_type            :string
#  lab_name                :text
#  labnr                   :string
#  lat                     :text
#  lng                     :text
#  material                :string
#  periods                 :jsonb
#  reference               :jsonb
#  site                    :string
#  site_type               :string
#  source_database         :text
#  species                 :string
#  std                     :integer
#  typochronological_units :jsonb
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
