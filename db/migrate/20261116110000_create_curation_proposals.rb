# frozen_string_literal: true

# Stores actionable suggestions separately from curated records.
class CreateCurationProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :curation_proposals do |t|
      t.references :subject, polymorphic: true, null: false, index: false
      t.string :kind, null: false
      t.string :target_key, null: false
      t.jsonb :evidence, null: false, default: {}
      t.timestamps

      t.index %i[subject_type subject_id kind target_key], unique: true, name: 'index_curation_proposals_on_target'
      t.index %i[kind id]
    end
  end
end
