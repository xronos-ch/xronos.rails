class AddEvenMoreIndexes < ActiveRecord::Migration[6.1]
  def change
    # Index:
    # - default order_by columns
    # - columns we're probably going to filter on at some point
    add_index :c14_labs, :name
    add_index :c14_labs, :active

    add_index :c14s, :method
    
    add_index :measurement_states, :name

    add_index :references, :short_ref

    add_index :samples, :position_crs

    add_index :source_databases, :name
    add_index :source_databases, :licence

    add_index :typos, :name

    add_index :versions, :whodunnit
    add_index :versions, :event
  end
end
