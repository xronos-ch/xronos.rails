class ChangeLatAndLonToBeDecimalInSites < ActiveRecord::Migration[5.2]
  def change
		change_column :sites, :lat, :decimal
		change_column :sites, :lng, :decimal
  end
end
