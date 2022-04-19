class AddCountryToSites < ActiveRecord::Migration[6.1]
  def change
    # New column for attribute 'country' (ideally containing a country code)
    add_column :sites, :country, :string
    
    # Migrate existing data from countries table
    execute %(
      UPDATE sites
      SET country = countries.name
      FROM countries
      WHERE sites.country_id = countries.id
    )

    # Drop countries table
    drop_table :countries
    remove_column :sites, :country_id
  end
end
