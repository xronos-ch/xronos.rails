class ChangeReadOptionsToJsonb < ActiveRecord::Migration[6.1]
  def change
    change_column :import_tables, :read_options, :jsonb
  end
end
