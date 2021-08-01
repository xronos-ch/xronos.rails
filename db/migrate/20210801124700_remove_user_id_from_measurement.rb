class RemoveUserIdFromMeasurement < ActiveRecord::Migration[5.2]
  def change
    remove_column :measurements, :user_id, :bigint
  end
end
