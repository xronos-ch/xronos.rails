namespace :taxons do
  desc "Try to match unknown taxons to GBIF Backbone Taxonomy (exact matches only)"
  task match_unknown: :environment do
    Taxon.unknown_taxon.find_each do |taxon|
      taxon.set_gbif_id_from_match
      taxon.revision_comment = "Matched to GBIF Backbone Taxonomy"
      taxon.save
    end
  end

end
