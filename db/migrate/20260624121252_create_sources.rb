class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :version
      t.text :path
      t.jsonb :file_manifest, default: {}
      t.string :source_url
      t.date :access_date
      t.string :license
      t.text :notes
      t.timestamps
    end

    add_index :sources, [:name, :version], unique: true, where: "version IS NOT NULL"
  end
end
