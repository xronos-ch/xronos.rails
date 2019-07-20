class EmbedSitePhaseBetweenSiteAndArchObject < ActiveRecord::Migration[5.2]
  def change
    remove_column :arch_objects, :site_id
    add_column :arch_objects, :site_phase_id, :integer
    add_column :site_phases, :site_id, :integer
  end
end
