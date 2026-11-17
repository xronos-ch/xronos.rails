class CreateFunctionalClassificationCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :functional_classification_categories do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
