class RenameLinkedResourcesPolymorphicIndexToDefault < ActiveRecord::Migration[8.0]
  def up
    # The default Rails name would be 84 chars; PostgreSQL's identifier limit
    # is 63. Use a shorter, semantic custom name instead.
    rename_index :linked_resources,
      "index_lod_links_on_polymorphic_source_and_external_id",
      "index_linked_resources_on_polymorphic_source_and_external_id"
  end

  def down
    rename_index :linked_resources,
      "index_linked_resources_on_polymorphic_source_and_external_id",
      "index_lod_links_on_polymorphic_source_and_external_id"
  end
end
