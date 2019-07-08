class CreateMeasurements < ActiveRecord::Migration[5.2]
  def change
    create_table :measurements do |t|
      t.integer :year
      t.string :labnr
      t.integer :sample_id
      t.integer :lab_id

      t.timestamps
    end

    add_foreign_key :measurements,
                    :samples,
                    column: :sample_id
    add_index :measurements, :sample_id

    add_foreign_key :measurements,
                    :labs,
                    column: :lab_id
    add_index :measurements, :lab_id

  end
end
