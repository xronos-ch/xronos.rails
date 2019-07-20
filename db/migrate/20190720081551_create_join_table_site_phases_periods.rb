class CreateJoinTableSitePhasesPeriods < ActiveRecord::Migration[5.2]
  def change
    create_join_table :site_phases, :periods do |t|
      t.index [:site_phase_id, :period_id], name: :index_spp
    end
  end
end
