class RenameMeasurementToXron < ActiveRecord::Migration[6.1]
  def change
    rename_table :measurements, :xrons
  end
end
