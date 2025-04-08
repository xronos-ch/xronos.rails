class AddAttributesToC14Lab < ActiveRecord::Migration[7.2]
  def change
    add_column :c14_labs, :short_name, :string
    add_index :c14_labs, :short_name, unique: true
    add_column :c14_labs, :city, :string
    add_column :c14_labs, :url, :string
    add_reference :c14_labs, :successor, foreign_key: { to_table: :c14_labs }
  end
end
