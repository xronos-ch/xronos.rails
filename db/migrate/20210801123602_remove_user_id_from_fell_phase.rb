class RemoveUserIdFromFellPhase < ActiveRecord::Migration[5.2]
  def change
    remove_column :fell_phases, :user_id, :bigint
  end
end
