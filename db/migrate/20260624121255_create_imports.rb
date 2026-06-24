class CreateImports < ActiveRecord::Migration[8.0]
  def change
    create_table :imports do |t|
      t.references :source, null: false, foreign_key: true
      t.jsonb :records_created, default: {}
      t.jsonb :records_updated, default: {}
      t.boolean :success, default: false
      t.text :error
      t.timestamps
    end
  end
end
