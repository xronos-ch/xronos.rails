class RenameC14MeasurementToC14 < ActiveRecord::Migration[6.1]
  def change
    rename_table :c14_measurements, :c14s
  end
end
