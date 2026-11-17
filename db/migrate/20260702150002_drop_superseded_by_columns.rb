# frozen_string_literal: true

# Drops the superseded_by integer columns and their indexes from
# sites, c14s, references, and typos. The state previously encoded in
# these columns is now held by the Supersession / SupersessionEvent
# tables introduced in the prior migrations.
#
# Reversible: re-adds the column (no data restoration).
class DropSupersededByColumns < ActiveRecord::Migration[8.0]
  def up
    remove_index :c14s, :superseded_by if index_exists?(:c14s, :superseded_by)
    remove_index :references, :superseded_by if index_exists?(:references, :superseded_by)
    remove_index :typos, :superseded_by if index_exists?(:typos, :superseded_by)

    remove_column :c14s, :superseded_by
    remove_column :references, :superseded_by
    remove_column :sites, :superseded_by
    remove_column :typos, :superseded_by
  end

  def down
    add_column :sites, :superseded_by, :integer
    add_column :c14s, :superseded_by, :integer
    add_column :references, :superseded_by, :integer
    add_column :typos, :superseded_by, :integer

    add_index :c14s, :superseded_by
    add_index :references, :superseded_by
    add_index :typos, :superseded_by
  end
end
