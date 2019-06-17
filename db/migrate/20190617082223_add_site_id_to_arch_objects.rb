class AddSiteIdToArchObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :arch_objects, :site_id, :integer
  end
end
