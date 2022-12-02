class RenameCountryToCountryCode < ActiveRecord::Migration[6.1]
  def change
    rename_column :sites, :country, :country_code
  end
end
