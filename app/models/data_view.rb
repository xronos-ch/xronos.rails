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

class DataView < ApplicationRecord
  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def self.populated?
    Scenic.database.populated?(table_name)
  end
  
  private
 
  # This makes sure ActiveRecord won’t try to save anything using this model.
  def readonly?
    true
  end
end
