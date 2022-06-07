class AddUserRefToCurateImportTables < ActiveRecord::Migration[6.1]
  def change
    add_reference :curate_import_tables, :user, foreign_key: true
  end
end
