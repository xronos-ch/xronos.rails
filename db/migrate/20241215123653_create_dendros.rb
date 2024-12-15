class CreateDendros < ActiveRecord::Migration[7.0]
  def change
    create_table :dendros do |t|
      t.references :sample, null: false, foreign_key: true
      t.string :series_code, null: false
      t.string :name, null: false
      t.text :description
      t.integer :start_year
      t.integer :end_year
      t.boolean :is_anchored, default: false
      t.integer :offset
      t.jsonb :measurements, default: [], null: false

      t.timestamps
    end

    add_index :dendros, :series_code, unique: true
    add_index :dendros, :measurements, using: :gin
  end
end