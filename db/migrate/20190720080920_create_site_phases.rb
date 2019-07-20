class CreateSitePhases < ActiveRecord::Migration[5.2]
  def change
    create_table :site_phases do |t|
      t.string :name
      t.integer :approx_start_time
      t.integer :approx_end_time

      t.timestamps
    end
  end
end
