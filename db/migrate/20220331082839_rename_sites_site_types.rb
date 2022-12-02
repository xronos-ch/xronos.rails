class RenameSitesSiteTypes < ActiveRecord::Migration[6.1]
  def change
    rename_table :sites_site_types, :site_types_sites
  end
end
