class RemoveUserIdFromTypochronologicalUnit < ActiveRecord::Migration[5.2]
  def change
    remove_column :typochronological_units, :user_id, :bigint
  end
end
