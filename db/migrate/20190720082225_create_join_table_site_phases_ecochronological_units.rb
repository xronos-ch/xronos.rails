class CreateJoinTableSitePhasesEcochronologicalUnits < ActiveRecord::Migration[5.2]
  def change
    create_join_table :site_phases, :ecochronological_units do |t|
      t.index [:site_phase_id, :ecochronological_unit_id], name: :index_speu
    end
  end
end
