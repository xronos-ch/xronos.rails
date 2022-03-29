class MergeArchObjectAndSample < ActiveRecord::Migration[6.1]
  def change
    # NB: irreversible!
    remove_foreign_key :xrons, :samples
    execute "UPDATE xrons SET sample_id = samples.arch_object_id FROM samples WHERE sample_id = samples.id"
    drop_table :samples
    rename_table :arch_objects, :samples
  end
end
