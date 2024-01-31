class CreateCals < ActiveRecord::Migration[7.0]
  def change
    create_table :cals do |t|
      t.integer :source, index: true, null: false
      t.integer :c14_age
      t.integer :c14_error
      t.integer :c14_curve
      t.jsonb :prob_dist, null: false
      t.integer :taq
      t.integer :median
      t.integer :tpq

      t.index [ :source, :c14_age, :c14_error, :c14_curve ], unique: true

      t.timestamps
    end
  end
end
