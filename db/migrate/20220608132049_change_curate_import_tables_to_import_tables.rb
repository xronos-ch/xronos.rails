class ChangeCurateImportTablesToImportTables < ActiveRecord::Migration[6.1]
  def change
    rename_table :curate_import_tables, :import_tables
  end
end
