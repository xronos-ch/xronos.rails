class AddOnSiteObjectPositionIdToArchObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :arch_objects, :on_site_object_position_id, :integer
  end
end
