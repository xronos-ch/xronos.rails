class DropXrons < ActiveRecord::Migration[6.1]
  def change
    drop_table :xrons
    drop_table :xrons_references
  end
end
