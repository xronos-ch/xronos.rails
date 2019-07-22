class CreateSpeciesFirstTry < ActiveRecord::Migration[5.2]
  def change
    create_table :species do |t|
      t.string :family
      t.string :genus
      t.string :species
      t.string :subspecies

      t.timestamps
    end
  end
end
