class AddIndexesToApiv1Filters < ActiveRecord::Migration[6.1]
  def change
    add_index :c14s, :lab_identifier
    add_index :sites, :name
    add_index :site_types, :name
    add_index :sites, :country_code
    add_index :contexts, :name
    add_index :materials, :name
    add_index :taxons, :name
  end
end
