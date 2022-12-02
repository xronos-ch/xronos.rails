class DropFeatureTypes < ActiveRecord::Migration[6.1]
  def change
    drop_table :feature_types
  end
end
