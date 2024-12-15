class AddStatusToLodLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :lod_links, :status, :string, default: "pending", null: false
  end
end
