class CreateSitesWithCounts < ActiveRecord::Migration[8.0]
  def change
    create_view :sites_with_counts, materialized: true
  end
end
