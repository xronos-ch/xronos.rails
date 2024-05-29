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
#  ecochronological_units  :json
#  feature                 :string
#  feature_type            :string
#  lab_name                :text
#  labnr                   :string
#  lat                     :text
#  lng                     :text
#  material                :string
#  periods                 :json
#  reference               :json
#  site                    :string
#  site_type               :string
#  source_database         :text
#  species                 :string
#  std                     :integer
#  typochronological_units :json
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
