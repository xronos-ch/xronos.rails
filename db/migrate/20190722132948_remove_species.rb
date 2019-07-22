class RemoveSpecies < ActiveRecord::Migration[5.2]
  def change
    drop_table :species
  end
end
