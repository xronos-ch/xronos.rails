class CreateFunctionalClassificationConfidences < ActiveRecord::Migration[7.2]
  def change
    create_table :functional_classification_confidences do |t|
      t.string :name
      t.integer :rank
      t.text :description

      t.timestamps
    end
  end
end
