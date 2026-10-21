# frozen_string_literal: true

class AddIndexesToDataViews < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :data_views, name: 'index_data_views_on_id', algorithm: :concurrently
    add_index :data_views, :id, unique: true, name: 'index_data_views_on_id', algorithm: :concurrently
    add_index :data_views, :bp, name: 'index_data_views_on_bp', algorithm: :concurrently
  end
end
