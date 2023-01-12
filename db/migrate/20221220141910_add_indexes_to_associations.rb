class AddIndexesToAssociations < ActiveRecord::Migration[6.1]
  def change
    # Ensure all foreign key columns for associations are indexed
    add_index :contexts, :site_id

    add_index :samples,  :material_id
    add_index :samples,  :taxon_id
    add_index :samples,  :context_id
  end
end
