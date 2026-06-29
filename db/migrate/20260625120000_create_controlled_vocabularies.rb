class CreateControlledVocabularies < ActiveRecord::Migration[8.0]
  def change
    create_table :controlled_vocabularies do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
    add_index :controlled_vocabularies, :name, unique: true

    create_table :controlled_vocabulary_terms do |t|
      t.references :controlled_vocabulary, null: false, index: false
      t.string :name, null: false
      t.text :description
      t.string :ontology_name
      t.string :ontology_id

      t.timestamps
    end
    add_index :controlled_vocabulary_terms,
              [:controlled_vocabulary_id, :name],
              unique: true,
              name: "index_cv_terms_on_vocabulary_and_name"
    add_index :controlled_vocabulary_terms,
              [:ontology_name, :ontology_id],
              unique: true,
              where: "ontology_name IS NOT NULL AND ontology_id IS NOT NULL",
              name: "index_cv_terms_on_ontology"

    create_table :controlled_vocabulary_variants do |t|
      t.references :controlled_vocabulary_term, null: false, index: false
      t.string :value, null: false
      t.string :normalized, null: false

      t.timestamps
    end
    add_index :controlled_vocabulary_variants,
              [:controlled_vocabulary_term_id, :value],
              unique: true,
              name: "index_cv_variants_on_term_and_value"
    add_index :controlled_vocabulary_variants,
              [:controlled_vocabulary_term_id, :normalized],
              unique: true,
              name: "index_cv_variants_on_term_and_normalized"
  end
end
