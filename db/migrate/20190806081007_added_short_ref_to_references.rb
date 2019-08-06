class AddedShortRefToReferences < ActiveRecord::Migration[5.2]
  def change
    add_column :references, :short_ref, :string
  end
end
