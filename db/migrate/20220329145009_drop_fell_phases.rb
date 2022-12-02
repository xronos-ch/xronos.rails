class DropFellPhases < ActiveRecord::Migration[6.1]
  def change
    drop_table :fell_phases
  end
end
