class RemoveMeasurementReferences < ActiveRecord::Migration[5.2]
  def change
    drop_table :references_measurements
  end
end
