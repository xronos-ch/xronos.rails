class CreateIssuesUnknownTaxons < ActiveRecord::Migration[6.1]
  def change
    create_table :issues_unknown_taxons do |t|
      t.references :taxon, null: false, foreign_key: true

      t.timestamps
    end
  end
end
