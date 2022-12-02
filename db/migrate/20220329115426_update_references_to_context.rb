class UpdateReferencesToContext < ActiveRecord::Migration[6.1]
  def change
    rename_column :arch_objects, :site_phase_id, :context_id
  end
end
