class AddSequenceToCountryId < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        # add a sequence
        execute <<-SQL
          CREATE sequence countries_id_seq;
          SELECT setval('countries_id_seq', (SELECT MAX(id) FROM countries));
          ALTER TABLE countries
            ALTER id
              SET DEFAULT nextval('countries_id_seq');
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE countries
            ALTER id
              SET DEFAULT NULL;
          DROP sequence countries_id_seq;
        SQL
      end
    end
  end
end
