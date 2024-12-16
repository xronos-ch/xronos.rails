class CreateChronologies < ActiveRecord::Migration[7.0]
  def change
    create_table :chronologies do |t|
      t.string :name
      t.string :type
      t.string :method
      t.string :standardizing_method
      t.string :certainty
      t.jsonb :parameters, default: {}
      t.timestamps
    end
  end
end