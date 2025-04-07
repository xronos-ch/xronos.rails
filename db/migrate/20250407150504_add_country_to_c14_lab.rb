class AddCountryToC14Lab < ActiveRecord::Migration[7.2]
  def change
    add_column :c14_labs, :country_code, :string
  end
end
