# Merges semantically identical contexts (same site + same name, including NULL) 
# before enforcing database-level uniqueness constraints.
class AddContextNameConstraints < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up

    say_with_time "Normalising blank context names to NULL" do
      execute <<~SQL
        UPDATE contexts
        SET name = NULL
        WHERE name IS NOT NULL AND btrim(name) = '';
      SQL
    end

    say_with_time "Merging duplicate contexts per site and name" do
      rows = execute <<~SQL
        SELECT
          site_id,
          name,
          array_agg(id ORDER BY id) AS context_ids
        FROM contexts
        GROUP BY site_id, name
        HAVING COUNT(*) > 1;
      SQL

      rows.each do |row|
        context_ids = row["context_ids"]
        canonical_id = context_ids.first
        redundant_ids = context_ids.drop(1)

        next if redundant_ids.empty?

        # Move samples
        execute <<~SQL
          UPDATE samples
          SET context_id = #{canonical_id}
          WHERE context_id IN (#{redundant_ids.join(",")});
        SQL

        # Move functional classifications
        execute <<~SQL
          UPDATE functional_classifications
          SET context_id = #{canonical_id}
          WHERE context_id IN (#{redundant_ids.join(",")});
        SQL

        # Delete redundant contexts
        execute <<~SQL
          DELETE FROM contexts
          WHERE id IN (#{redundant_ids.join(",")});
        SQL
      end
    end

    say_with_time "Adding partial unique indexes" do
      # One unnamed (NULL) context per site
      add_index :contexts,
                :site_id,
                unique: true,
                where: "name IS NULL",
                name: "index_contexts_one_null_name_per_site",
                algorithm: :concurrently

      # Otherwise, names should be unique for each site
      add_index :contexts,
                [:site_id, :name],
                unique: true,
                where: "name IS NOT NULL",
                name: "index_contexts_unique_name_per_site",
                algorithm: :concurrently
    end
  end

  def down
    remove_index :contexts,
                 name: "index_contexts_one_null_name_per_site",
                 algorithm: :concurrently

    remove_index :contexts,
                 name: "index_contexts_unique_name_per_site",
                 algorithm: :concurrently
  end
end
