class AddSourceDatabaseIdtoC14Measurements < ActiveRecord::Migration[5.2]
  def change
    add_reference :c14_measurements, :source_database, index: true
    add_foreign_key :c14_measurements, :source_databases
  end
end
