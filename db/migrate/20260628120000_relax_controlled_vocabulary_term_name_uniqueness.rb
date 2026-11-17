class RelaxControlledVocabularyTermNameUniqueness < ActiveRecord::Migration[8.0]
  def change
    # Now that the seed includes the broader plant_anatomy namespace,
    # ~19 PO terms share a name with a UBERON term in the same vocabulary
    # (e.g. cortex, endothelium, primordium, silk, tapetum). Relax the
    # uniqueness to be scoped per ontology within the vocabulary.
    remove_index :controlled_vocabulary_terms,
                 name: "index_cv_terms_on_vocabulary_and_name"
    add_index :controlled_vocabulary_terms,
              [:controlled_vocabulary_id, :ontology_name, :name],
              unique: true,
              name: "index_cv_terms_on_vocabulary_ontology_and_name"
  end
end
