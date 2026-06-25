class AddRecordsSkippedToImports < ActiveRecord::Migration[8.0]
  def change
    add_column :imports, :records_skipped, :jsonb, default: {}
  end
end
