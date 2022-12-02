class DropEcochronologicalUnits < ActiveRecord::Migration[6.1]
  def change
    drop_table :ecochronological_units
    drop_table :ecochronological_units_site_phases
  end
end
