# frozen_string_literal: true

class RemoveStaleSearchDocuments < ActiveRecord::Migration[8.0]
  def up
    { 'Site' => 'sites', 'C14' => 'c14s', 'Reference' => 'references' }.each do |type, table|
      execute <<~SQL
        DELETE FROM pg_search_documents AS document
        WHERE document.searchable_type = #{connection.quote(type)}
          AND (
            NOT EXISTS (
              SELECT 1 FROM #{connection.quote_table_name(table)} AS record
              WHERE record.id = document.searchable_id
            )
            OR EXISTS (
              SELECT 1 FROM supersessions
              WHERE superseded_type = document.searchable_type
                AND superseded_id = document.searchable_id
            )
          )
      SQL
    end
  end

  def down
    # Search documents are derived from the current searchable records.
  end
end
