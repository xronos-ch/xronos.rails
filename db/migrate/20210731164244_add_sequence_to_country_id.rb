class AddSequenceToCountryId < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
          # add a sequence
          execute <<-SQL
            CREATE sequence countries_id_seq;
            SELECT setval('countries_id_seq', (SELECT MAX(id) FROM countries));
            ALTER TABLE countries
              ALTER id
                SET DEFAULT nextval('countries_id_seq');
              SQL
        end
      end
      dir.down do
        if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
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
end
