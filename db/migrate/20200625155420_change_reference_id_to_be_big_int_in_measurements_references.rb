class ChangeReferenceIdToBeBigIntInMeasurementsReferences < ActiveRecord::Migration[5.2]
  def up
    change_column :measurements_references, :reference_id, :integer, using: 'reference_id::integer'
  end

  def down
    change_column :measurements_references, :reference_id, :boolean, using: 'reference_id::boolean'
  end
end
