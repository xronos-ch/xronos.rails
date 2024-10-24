class RemoveProbDistFromCals < ActiveRecord::Migration[7.0]
  def change
    remove_column :cals, :prob_dist, :jsonb
  end
end
