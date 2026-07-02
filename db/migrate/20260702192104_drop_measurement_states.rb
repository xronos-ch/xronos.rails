class DropMeasurementStates < ActiveRecord::Migration[8.0]
  def change
    drop_table :measurement_states
  end
end
