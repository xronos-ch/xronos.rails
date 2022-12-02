class ReassociateSiteTypeWithSite < ActiveRecord::Migration[6.1]
  def change

    # Change site type from a many-to-one association with context (formerly 
    # site_phase) to a many-to-many association with site.
    create_table :sites_site_types, id: false do |t|
      t.belongs_to :site
      t.belongs_to :site_type
    end

    # Migrate existing associations
    execute %(
      INSERT INTO sites_site_types
      SELECT site_id, site_type_id FROM contexts
      WHERE site_id IS NOT NULL AND site_type_id IS NOT NULL
    )

    # Drop old association
    remove_reference :contexts, :site_type
  end
end
