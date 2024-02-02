class RenameMedianToCentreInCals < ActiveRecord::Migration[7.0]
  def change
    rename_column :cals, :median, :centre
  end
end
