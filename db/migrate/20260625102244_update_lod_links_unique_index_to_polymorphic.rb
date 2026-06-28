class UpdateLodLinksUniqueIndexToPolymorphic < ActiveRecord::Migration[8.0]
  def change
    remove_index :lod_links,
                 name: "index_lod_links_on_source_and_external_id",
                 if_exists: true

    add_index :lod_links,
              [:linkable_type, :linkable_id, :source, :external_id],
              unique: true,
              name: "index_lod_links_on_polymorphic_source_and_external_id",
              if_not_exists: true
  end
end