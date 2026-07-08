# TODO: Phase 1 of duplicate-processing port (origin/duplicates @ c21163fd).
# Adds superseded_by to the remaining models that will include Supersedable
# (Reference, C14, Typo). Sites already has the column.
class AddSupersededByToSupersedable < ActiveRecord::Migration[8.0]
  def change
    add_column :c14s, :superseded_by, :integer
    add_column :references, :superseded_by, :integer
    add_column :typos, :superseded_by, :integer

    add_index :c14s, :superseded_by
    add_index :references, :superseded_by
    add_index :typos, :superseded_by
  end
end
