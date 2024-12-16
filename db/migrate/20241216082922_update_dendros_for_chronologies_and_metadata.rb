class UpdateDendrosForChronologiesAndMetadata < ActiveRecord::Migration[7.0]
  def change
    change_table :dendros do |t|
      # Project-level metadata
      t.string :project_title
      t.text :project_objective
      t.datetime :project_start_date
      t.datetime :project_end_date

      # Object-level metadata
      t.string :object_title
      t.string :object_type
      t.text :object_description
      t.jsonb :object_dimensions, default: {}

      # Dendrochronological interpretation
      t.integer :pith_year
      t.integer :death_year
      t.integer :first_year
      t.integer :last_year
      t.jsonb :wood_completeness, default: {}

      # Chronology foreign key
      t.bigint :chronology_id, index: true
      t.jsonb :parameters, default: {}
    end

    add_foreign_key :dendros, :chronologies
  end
end