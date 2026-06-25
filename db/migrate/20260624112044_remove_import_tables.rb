class RemoveImportTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :import_tables
  end

  def down
    create_table :import_tables do |t|
      t.string :file
      t.datetime :imported_at, precision: nil
      t.references :user, foreign_key: true
      t.jsonb :read_options
      t.jsonb :mapping
      t.timestamps
    end
  end
end
