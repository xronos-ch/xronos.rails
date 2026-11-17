class DropWikidataLinks < ActiveRecord::Migration[8.0]
  def up
    drop_table :wikidata_links
  end

  def down
    create_table :wikidata_links do |t|
      t.integer :qid
      t.references :wikidata_linkable, polymorphic: true
      t.timestamps
    end

    add_index :wikidata_links, :qid, name: "index_wikidata_links_on_qid"
    add_index :wikidata_links, [:wikidata_linkable_type, :wikidata_linkable_id],
      name: "index_wikidata_links_on_linkable_type_and_linkable_id"
    add_index :wikidata_links, [:wikidata_linkable_type, :wikidata_linkable_id],
      name: "index_wikidata_links_on_wikidata_linkable"
  end
end
