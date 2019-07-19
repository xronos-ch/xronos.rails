class AddC14MeasurementIdToMeasurements < ActiveRecord::Migration[5.2]
  def change
    add_column :measurements, :c14_measurement_id, :integer

    add_foreign_key :measurements,
                    :c14_measurements,
                    column: :c14_measurement_id
    add_index :measurements, :c14_measurement_id
  end
end
