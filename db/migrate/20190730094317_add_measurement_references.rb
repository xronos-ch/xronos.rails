class AddMeasurementReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :references_measurements do |t|
      t.belongs_to :reference, index: true
      t.belongs_to :measurement, index: true
      t.string :page
      t.timestamps
    end
  end
end
