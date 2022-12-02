class MergeOnSiteObjectPositionWithSample < ActiveRecord::Migration[6.1]
  def change
    add_column :samples, :position_description, :text
    add_column :samples, :position_x, :decimal
    add_column :samples, :position_y, :decimal
    add_column :samples, :position_z, :decimal
    add_column :samples, :position_crs, :text

    execute %(
      UPDATE samples
      SET
        position_description = pos.feature,
        position_x = pos."coord_X",
        position_y = pos."coord_Y",
        position_z = pos."coord_Z",
        position_crs = pos.coord_reference_system
      FROM on_site_object_positions pos
      WHERE samples.on_site_object_position_id = pos.id
    )

    remove_reference :samples, :on_site_object_position
    drop_table :on_site_object_positions
  end
end
