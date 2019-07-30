class AddParentIdToPeriodsTypochronologicalUnitsEcochronologicalUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :periods, :parent_id, :integer
    add_column :typochronological_units, :parent_id, :integer
    add_column :ecochronological_units, :parent_id, :integer
  end
end
