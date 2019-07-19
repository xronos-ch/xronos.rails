class SimplifySpeciesVariables < ActiveRecord::Migration[5.2]
  def change
    remove_column :species, :family
    remove_column :species, :genus
    remove_column :species, :subspecies
    rename_column :species, :species, :name
  end
end
