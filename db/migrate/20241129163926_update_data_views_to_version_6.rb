class UpdateDataViewsToVersion6 < ActiveRecord::Migration[7.0]
  def change
    update_view :data_views, version: 6, revert_to_version: 5, materialized: true
  end
end
