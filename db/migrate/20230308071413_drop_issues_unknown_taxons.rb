class DropIssuesUnknownTaxons < ActiveRecord::Migration[6.1]
  def change
    drop_table :issues_unknown_taxons
  end
end
