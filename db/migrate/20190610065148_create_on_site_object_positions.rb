class CreateOnSiteObjectPositions < ActiveRecord::Migration[5.2]
  def change
    create_table :on_site_object_positions do |t|
      t.string :feature
      t.string :site_grid_square
      t.string :coord_reference_system
      t.decimal :coord_X
      t.decimal :coord_Y
      t.decimal :coord_Z

      t.timestamps
    end
  end
end
