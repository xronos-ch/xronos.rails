class AddGbifIdToTaxon < ActiveRecord::Migration[6.1]
  def change
    add_column :taxons, :gbif_id, :integer
    add_index :taxons, :gbif_id
  end
end
