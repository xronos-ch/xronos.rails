class CreateArchObjects < ActiveRecord::Migration[5.2]
  def change
    create_table :arch_objects do |t|

      t.timestamps
    end
  end
end
