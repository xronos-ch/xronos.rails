class AddReplacedByToMeasurement < ActiveRecord::Migration[6.1]
  def change
    add_column :measurements, :replaced_by, :integer
  end
end
