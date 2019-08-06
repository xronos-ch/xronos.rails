class RemovedAbbreviationFromCountries < ActiveRecord::Migration[5.2]
  def change
    remove_column :countries, :abbreviation
  end
end
