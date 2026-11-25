class AddWaneyEdgeToDendros < ActiveRecord::Migration[7.2]
  def change
    add_column :dendros, :waney_edge, :boolean
  end
end
