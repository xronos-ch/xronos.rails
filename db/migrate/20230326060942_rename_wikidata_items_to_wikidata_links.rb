class RenameWikidataItemsToWikidataLinks < ActiveRecord::Migration[6.1]
  def change
    drop_table :wikidata_items

    create_table :wikidata_links do |t|
      t.integer :qid
      t.references :wikidata_linkable, polymorphic: true
      t.timestamps
    end

    add_index :wikidata_links, :qid
    add_index :wikidata_links, [ :wikidata_linkable_type, :wikidata_linkable_id ], name: "index_wikidata_links_on_linkable_type_and_linkable_id" # otherwise too long
  end
end
