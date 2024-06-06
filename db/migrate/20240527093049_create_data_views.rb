class CreateDataViews < ActiveRecord::Migration[7.0]
  def change
    create_view :data_views, materialized: true
  end
end
