class RemovedYearFromMeasurements < ActiveRecord::Migration[5.2]
  def change
    remove_column :measurements, :year
  end
end
