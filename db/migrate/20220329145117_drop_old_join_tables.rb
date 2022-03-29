class DropOldJoinTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :fell_phases_references
    drop_table :site_phases_typochronological_units
  end
end
