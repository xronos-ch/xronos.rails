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
#  labnr                   :string
#  lat                     :text
#  lng                     :text
#  material                :string
#  periods                 :json
#  reference               :json
#  site                    :string
#  site_type               :string
#  species                 :string
#  std                     :integer
#  typochronological_units :json
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
