class CreateDendroMeasurements < ActiveRecord::Migration[5.2]
  def change
    create_table :dendro_measurements do |t|
      t.integer :age
      t.integer :start_age_deviation
      t.integer :end_age_deviation
      t.string :dating_quality_estimation_category
    end
  end
end
