class AddDelta15nToC14s < ActiveRecord::Migration[8.0]
  def change
    add_column :c14s, :delta_15n, :float
  end
end
