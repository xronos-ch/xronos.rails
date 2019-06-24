class AddFeatureTypeIdToOnSiteObjectPositions < ActiveRecord::Migration[5.2]
  def change
    add_column :on_site_object_positions, :feature_type_id, :integer
  end
end
