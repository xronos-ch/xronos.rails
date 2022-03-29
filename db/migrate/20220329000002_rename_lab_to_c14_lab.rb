class RenameLabToC14Lab < ActiveRecord::Migration[6.1]
  def change
    rename_table :labs, :c14_labs
  end
end
