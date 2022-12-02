class CreateCurateImportTables < ActiveRecord::Migration[6.1]
  def change
    create_table :curate_import_tables do |t|
      t.string :file
      t.datetime :imported_at

      t.timestamps
    end
  end
end
