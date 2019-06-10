class CreateCultures < ActiveRecord::Migration[5.2]
  def change
    create_table :cultures do |t|
      t.string :name
      t.integer :approx_start_ime
      t.integer :approx_end_time

      t.timestamps
    end
  end
end
