class AddNameToSamples < ActiveRecord::Migration[8.0]
  def change
    add_column :samples, :name, :string
  end
end
