class MergeAndReassociateTypos < ActiveRecord::Migration[6.1]
  def change

    # NB: irreversible!

    # Create temporary columns to keep track of associations
    add_column :typos, :context_id, :integer
    add_column :samples, :typo_id, :integer

    # Join typos and contexts (formerly periods and site_phases)
    execute %(
      INSERT INTO typos 
        (name, approx_start_time, approx_end_time, created_at, updated_at, parent_id, context_id) 
      SELECT 
        name, approx_start_time, approx_end_time, created_at, updated_at, parent_id, 
        site_phase_id AS context_id 
      FROM typos 
      INNER JOIN periods_site_phases 
      ON typos.id = periods_site_phases.period_id
    )

    # Repeat for typochronological_units (merging into typos)
    execute %(
      INSERT INTO typos 
        (name, approx_start_time, approx_end_time, created_at, updated_at, parent_id, context_id) 
      SELECT 
        name, approx_start_time, approx_end_time, created_at, updated_at, parent_id, 
        site_phase_id AS context_id 
      FROM typochronological_units 
      INNER JOIN site_phases_typochronological_units 
      ON typochronological_units.id = site_phases_typochronological_units.typochronological_unit_id
    )

    # Remove unjoined data from typos
    execute "DELETE FROM typos WHERE context_id IS NULL"
    
    # Create associations path typo->xron->sample->context using temporary columns
    add_reference :xrons, :typo
    execute %(
      INSERT INTO xrons 
        (typo_id, created_at, updated_at, measurement_state_id)
      SELECT 
        id AS typo_id, 
        created_at, updated_at,
        1 AS measurement_state_id
      FROM typos
    )
    execute %(
      INSERT INTO samples
        (created_at, updated_at, context_id, typo_id)
      SELECT
        created_at, updated_at, context_id, 
        id AS typo_id
      FROM typos
    )
    execute "UPDATE xrons SET sample_id = samples.id FROM samples WHERE xrons.typo_id = samples.typo_id"
    
    # Drop temporary columns
    remove_column :samples, :typo_id
    remove_column :typos, :context_id

    # Drop typochronological_units
    drop_table :typochronological_units

  end
end
