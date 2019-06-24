class AddSiteTypeIdToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :site_type_id, :integer
  end
end
