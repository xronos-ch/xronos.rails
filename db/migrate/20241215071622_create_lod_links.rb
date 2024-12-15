class CreateLodLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :lod_links do |t|
      t.string :source, null: false                  # e.g., "Wikidata"
      t.string :external_id, null: false            # Unique identifier for the LOD
      t.string :linkable_type, null: false          # Polymorphic association type
      t.bigint :linkable_id, null: false            # Polymorphic association ID
      t.jsonb :data                                 # Optional metadata
      t.timestamps
    end

    add_index :lod_links, [:source, :external_id], unique: true
    add_index :lod_links, [:linkable_type, :linkable_id]
  end
end