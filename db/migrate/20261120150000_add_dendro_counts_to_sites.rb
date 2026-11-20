class AddDendroCountsToSites < ActiveRecord::Migration[8.0]
  def change
    update_view :sites_with_counts, version: 2, revert_to_version: 1, materialized: true
  end
end
