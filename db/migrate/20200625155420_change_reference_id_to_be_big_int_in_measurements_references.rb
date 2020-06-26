class ChangeReferenceIdToBeBigIntInMeasurementsReferences < ActiveRecord::Migration[5.2]
  def up
    change_column :measurements_references, :reference_id, 'integer USING CAST(reference_id AS integer)'
  end

  def down
    change_column :measurements_references, :reference_id, 'boolean USING CAST(reference_id AS boolean)'
  end
end
