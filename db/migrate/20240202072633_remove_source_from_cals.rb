class RemoveSourceFromCals < ActiveRecord::Migration[7.0]
  def change
    remove_column :cals, :source, :integer
  end
end
