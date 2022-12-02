class RenameSpeciesToTaxon < ActiveRecord::Migration[6.1]
  def change
    rename_table :species, :taxons
  end
end
