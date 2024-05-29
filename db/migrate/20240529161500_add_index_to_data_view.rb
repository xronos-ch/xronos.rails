class AddIndexToDataView < ActiveRecord::Migration[7.0]
  def change
    add_index :data_views, :id
    add_index :data_views, :labnr
    add_index :data_views, :site
    add_index :data_views, :site_type
    add_index :data_views, :country
    add_index :data_views, :feature
    add_index :data_views, :material
    add_index :data_views, :species
  end
end
