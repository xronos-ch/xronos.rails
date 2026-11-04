class AddCslAndDoiToReferences < ActiveRecord::Migration[8.0]
  def change
    add_column :references, :csl, :jsonb
    add_column :references, :doi, :string
    add_index :references, :doi
  end
end
