class CreateSupersessionEvents < ActiveRecord::Migration[8.0]
  def change # rubocop:disable Metrics/MethodLength
    create_table :supersession_events do |t|
      t.string :event_type, null: false
      t.references :superseded, polymorphic: true, null: false
      t.references :superseded_by, polymorphic: true, null: false
      t.text :comment
      t.timestamps
    end

    # Replace the default polymorphic indexes with composite
    # (polymorphic + created_at) indexes that serve the
    # merge_history and "what was ever merged into X" queries.
    remove_index :supersession_events, name: 'index_supersession_events_on_superseded'
    remove_index :supersession_events, name: 'index_supersession_events_on_superseded_by'

    add_index :supersession_events,
              %i[superseded_type superseded_id created_at],
              name: 'index_supersession_events_on_superseded'

    add_index :supersession_events,
              %i[superseded_by_type superseded_by_id created_at],
              name: 'index_supersession_events_on_superseded_by'

    add_index :supersession_events,
              %i[event_type created_at],
              name: 'index_supersession_events_on_event_type'
  end
end
