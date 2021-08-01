class RemoveUserIdFromPeriod < ActiveRecord::Migration[5.2]
  def change
    remove_column :periods, :user_id, :bigint
  end
end
