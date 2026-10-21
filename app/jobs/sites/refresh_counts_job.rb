class Sites::RefreshCountsJob < ApplicationJob
  queue_as :default

  def perform
    Scenic.database.refresh_materialized_view(
      :sites_with_counts,
      concurrently: true,
      cascade: false
    )
  end
end
