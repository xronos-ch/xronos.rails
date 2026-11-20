class AllowRepeatedDendroSeriesCodes < ActiveRecord::Migration[8.0]
  def change
    remove_index :dendros, :series_code, unique: true
    add_index :dendros, :series_code
  end
end
