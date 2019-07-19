class CreateC14MeasurementsFirstTry < ActiveRecord::Migration[5.2]
  def change
    create_table :c14_measurements do |t|
      t.integer :bp
      t.integer :std
      t.decimal :delta_c13
      t.decimal :delta_c13_std
      t.string :method
    end
  end
end
