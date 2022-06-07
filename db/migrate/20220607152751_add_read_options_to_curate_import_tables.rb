class AddReadOptionsToCurateImportTables < ActiveRecord::Migration[6.1]
  def change
    add_column :curate_import_tables, :read_options, :json
  end
end
