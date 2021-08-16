class AddMeasurementStateToMeasurement < ActiveRecord::Migration[6.1]
  def change
    add_reference :measurements, :measurement_state, null: false, foreign_key: true
  end
end
