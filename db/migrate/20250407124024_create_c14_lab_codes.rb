class CreateC14LabCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :c14_lab_codes do |t|
      t.belongs_to :c14_lab, index: true, foreign_key: true

      t.string :lab_code, null: false, index: true
      t.boolean :canonical, null: false
      t.timestamps
    end
  end
end
