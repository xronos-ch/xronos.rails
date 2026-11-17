# frozen_string_literal: true

class UpdateDataViewsToVersion7 < ActiveRecord::Migration[8.0]
  def change
    update_view :data_views, version: 7, revert_to_version: 6, materialized: true
  end
end
