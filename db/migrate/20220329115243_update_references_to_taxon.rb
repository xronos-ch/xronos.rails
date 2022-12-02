class UpdateReferencesToTaxon < ActiveRecord::Migration[6.1]
  def change
    rename_column :arch_objects, :species_id, :taxon_id
  end
end
