class AddSpeciesIdToArchObjects < ActiveRecord::Migration[5.2]
  def change
    add_column :arch_objects, :species_id, :integer
  end
end
