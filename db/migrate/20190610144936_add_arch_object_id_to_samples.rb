class AddArchObjectIdToSamples < ActiveRecord::Migration[5.2]
  def change
		add_column :samples, :arch_object_id, :integer
  end
end
