class AddSearchableToReferences < ActiveRecord::Migration[8.0]
  def change
    add_column :references, :searchable, :virtual,
      type: :tsvector,
      stored: true,
      as: <<~SQL.squish
        setweight(to_tsvector('simple', coalesce(short_ref, '')), 'A')
        || setweight(jsonb_to_tsvector('simple', coalesce(csl, 'null'::jsonb), '["string", "numeric"]'::jsonb), 'B')
      SQL

    add_index :references, :searchable, using: :gin
  end
end
