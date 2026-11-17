class PrefixWikidataExternalIds < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE linked_resources
      SET external_id = 'Q' || external_id
      WHERE source = 'Wikidata'
        AND external_id IS NOT NULL
        AND external_id <> ''
        AND external_id NOT LIKE 'Q%'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE linked_resources
      SET external_id = SUBSTRING(external_id FROM 2)
      WHERE source = 'Wikidata'
        AND external_id LIKE 'Q%'
    SQL
  end
end
