class AddSupersededByToSupersedable < ActiveRecord::Migration[6.1]
  def change
    #add_column :c14s, :superseded_by, :integer # already done
    add_column :c14_labs, :superseded_by, :integer
    add_column :contexts, :superseded_by, :integer
    add_column :materials, :superseded_by, :integer
    add_column :references, :superseded_by, :integer
    add_column :samples, :superseded_by, :integer
    add_column :c14s, :superseded_by, :integer
    #add_column :sites, :superseded_by, :integer # already done
    add_column :site_types, :superseded_by, :integer
    add_column :taxons, :superseded_by, :integer
    add_column :typos, :superseded_by, :integer

    #add_index :c14s, :superseded_by # already done
    add_index :c14_labs, :superseded_by
    add_index :contexts, :superseded_by
    add_index :materials, :superseded_by
    add_index :references, :superseded_by
    add_index :samples, :superseded_by
    add_index :c14s, :superseded_by
    add_index :sites, :superseded_by
    add_index :site_types, :superseded_by
    add_index :taxons, :superseded_by
    add_index :typos, :superseded_by
  end
end
