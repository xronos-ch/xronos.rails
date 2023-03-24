class CreateWikidataItems < ActiveRecord::Migration[6.1]
  def change
    create_table :wikidata_items do |t|
      t.integer :qid
      t.references :wikidata_link, polymorphic: true
      t.timestamps
    end

    add_index :wikidata_items, :qid
    add_index :wikidata_items, [ :wikidata_link_type, :qid ]
    add_index :wikidata_items, [ :wikidata_link_type, :wikidata_link_id ]
  end
end
