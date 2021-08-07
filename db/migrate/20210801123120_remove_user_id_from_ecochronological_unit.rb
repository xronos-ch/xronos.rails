class RemoveUserIdFromEcochronologicalUnit < ActiveRecord::Migration[5.2]
  def change
    remove_column :ecochronological_units, :user_id, :bigint
  end
end
