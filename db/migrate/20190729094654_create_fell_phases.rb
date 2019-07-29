class CreateFellPhases < ActiveRecord::Migration[5.2]
  def change
    create_table :fell_phases do |t|
      t.string :name
      t.integer :start_time
      t.integer :end_time
      t.integer :site_id

      t.timestamps
    end
    add_index :fell_phases, :site_id
  end
end
