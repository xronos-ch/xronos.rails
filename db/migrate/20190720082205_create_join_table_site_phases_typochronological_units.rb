class CreateJoinTableSitePhasesTypochronologicalUnits < ActiveRecord::Migration[5.2]
  def change
    create_join_table :site_phases, :typochronological_units do |t|
      t.index [:site_phase_id, :typochronological_unit_id], name: :index_sptu
    end
  end
end
