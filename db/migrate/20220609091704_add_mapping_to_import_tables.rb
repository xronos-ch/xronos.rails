class AddMappingToImportTables < ActiveRecord::Migration[6.1]
  def change
    add_column :import_tables, :mapping, :jsonb
  end
end
