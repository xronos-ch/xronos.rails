class AddSnapshotIdToVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :snapshot_id, :bigint
    add_index :versions, :snapshot_id
  end
end
