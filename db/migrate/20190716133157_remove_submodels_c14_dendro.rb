class RemoveSubmodelsC14Dendro < ActiveRecord::Migration[5.2]
  def change
    drop_table(:c14_measurements)
    drop_table(:dendro_measurements)
    remove_column :measurements, :actable_id, :integer
    remove_column :measurements, :actable_type, :string
  end
end
