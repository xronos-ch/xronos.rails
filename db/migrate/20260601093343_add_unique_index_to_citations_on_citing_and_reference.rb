class AddUniqueIndexToCitationsOnCitingAndReference < ActiveRecord::Migration[7.2]
  # Run 
  #     DRY_RUN=1 bin/rails citations:deduplicate 
  # to check for existing duplicates that would block this migration.
  #
  # If any are found, run 
  #     bin/rails citations:deduplicate 
  # to delete them.
  def change
    add_index :citations,
              %i[citing_type citing_id reference_id],
              unique: true,
              name: "index_citations_on_citing_and_reference"
  end
end
