class AddActableColumnsToMeasurement < ActiveRecord::Migration[5.2]
  def change
    add_column :measurements, :actable_id, :integer
    add_column :measurements, :actable_type, :string
  end
end
