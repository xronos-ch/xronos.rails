class AddIndexToSitesWithCounts < ActiveRecord::Migration[8.0]
  def change
    add_index :sites_with_counts, :id, unique: true
  end
end
