class RemoveUserIdFromSitePhase < ActiveRecord::Migration[5.2]
  def change
    remove_column :site_phases, :user_id, :bigint
  end
end
