class CreateMeasurements < ActiveRecord::Migration[5.2]
  def change
    create_table :measurements do |t|
      t.integer :year
      t.string :labnr
      t.references :sample, foreign_key: true
      t.references :lab, foreign_key: true

      t.timestamps
    end
  end
end
