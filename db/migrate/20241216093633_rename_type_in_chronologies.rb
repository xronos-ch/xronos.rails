class RenameTypeInChronologies < ActiveRecord::Migration[7.0]
  def change
    rename_column :chronologies, :type, :chronology_type
  end
end