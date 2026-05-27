class CreateFunctionalClassifications < ActiveRecord::Migration[7.2]
  def change
    create_table :functional_classifications do |t|
      t.references :assignable, polymorphic: true, null: false
      t.references :functional_classification_category, null: false, foreign_key: true
      t.references :functional_classification_confidence, null: false, foreign_key: true
      t.string :source
      t.text :note

      t.timestamps
    end

    add_index :functional_classifications,
              [
                :assignable_type,
                :assignable_id,
                :functional_classification_category_id
              ],
              unique: true,
              name: "idx_functional_classifications_unique_category"
  end
end