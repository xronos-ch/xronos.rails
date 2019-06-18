class AddMaterialIdToArchObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :arch_objects, :material_id, :integer
  end
end
