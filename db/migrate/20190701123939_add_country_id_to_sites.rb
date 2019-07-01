class AddCountryIdToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :country_id, :integer
  end
end
