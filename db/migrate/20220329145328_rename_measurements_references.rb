class RenameMeasurementsReferences < ActiveRecord::Migration[6.1]
  def change
    rename_table :measurements_references, :xrons_references
    rename_column :xrons_references, :measurement_id, :xron_id
  end
end
