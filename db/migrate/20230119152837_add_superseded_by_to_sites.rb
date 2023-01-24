class AddSupersededByToSites < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :superseded_by, :integer
  end
end
