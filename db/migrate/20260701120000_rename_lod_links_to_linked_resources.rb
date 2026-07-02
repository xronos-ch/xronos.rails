class RenameLodLinksToLinkedResources < ActiveRecord::Migration[8.0]
  def up
    rename_table :lod_links, :linked_resources
  end

  def down
    rename_table :linked_resources, :lod_links
  end
end
