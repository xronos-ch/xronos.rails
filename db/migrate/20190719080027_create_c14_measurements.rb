class CreateC14Measurements < ActiveRecord::Migration[5.2]
  def change
    create_table :c14_measurements do |t|
      t.integer :bp
      t.integer :std
      t.integer :cal_bp
      t.integer :cal_std
      t.float :delta_c13
      t.float :delta_c13_std
      t.string :method

      t.timestamps
    end
  end
end
