class RemoveParentIdFromTypos < ActiveRecord::Migration[8.0]
  def up
    execute 'LOCK TABLE typos IN ACCESS EXCLUSIVE MODE'
    if connection.select_value('SELECT 1 FROM typos WHERE parent_id IS NOT NULL LIMIT 1')
      raise ActiveRecord::MigrationError, 'typos.parent_id still contains values'
    end

    remove_column :typos, :parent_id
  end

  def down
    add_column :typos, :parent_id, :integer
  end
end
