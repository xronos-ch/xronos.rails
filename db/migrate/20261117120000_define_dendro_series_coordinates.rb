class DefineDendroSeriesCoordinates < ActiveRecord::Migration[8.0]
  def change
    change_table :dendros, bulk: true do |t|
      t.remove :start_year, :end_year, :offset, type: :integer
      t.integer :anchor_position
      t.integer :anchor_year
      t.string :measurement_variable
      t.string :measurement_unit
    end

    change_column_default :dendros, :is_anchored, from: false, to: nil
    add_check_constraint :dendros,
                         "(is_anchored IS TRUE AND anchor_position IS NOT NULL AND anchor_year IS NOT NULL) OR " \
                         "(is_anchored IS NOT TRUE AND anchor_position IS NULL AND anchor_year IS NULL)",
                         name: "dendros_calendar_anchor"
  end
end
