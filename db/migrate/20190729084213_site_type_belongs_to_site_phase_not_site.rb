class SiteTypeBelongsToSitePhaseNotSite < ActiveRecord::Migration[5.2]
  def change
    remove_column :sites, :site_type_id
    add_column :site_phases, :site_type_id, :integer
  end
end
