class AddLabIdToC14s < ActiveRecord::Migration[6.1]
  def change
    add_column :c14s, :lab_identifier, :string
    execute "UPDATE c14s SET lab_identifier = xrons.labnr FROM xrons WHERE c14s.id = xrons.c14_id"
  end
end
