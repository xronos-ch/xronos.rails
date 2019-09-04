class CreateSourceDatabases < ActiveRecord::Migration[5.2]
  def change
    create_table :source_databases do |t|
      t.string :name
      t.string :url
      t.text :citation
      t.string :licence

      t.timestamps
    end
  end
end
