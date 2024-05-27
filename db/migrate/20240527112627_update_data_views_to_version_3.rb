class UpdateDataViewsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view :data_views, version: 3, revert_to_version: 2,
      materialized: true
  end
end
