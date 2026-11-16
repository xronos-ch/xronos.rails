class RemoveParentIdFromTypos < ActiveRecord::Migration[8.0]
  def change
    remove_column :typos, :parent_id, :integer
  end
end
