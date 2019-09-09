class CreateJoinTableFellPhasesReferences < ActiveRecord::Migration[5.2]
  def change
    create_join_table :fell_phases, :references do |t|
      t.index [:fell_phase_id, :reference_id], name: :index_fpr
    end
  end
end
