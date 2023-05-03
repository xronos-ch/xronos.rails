namespace :taxons do
  desc "Try to match unknown taxons to GBIF Backbone Taxonomy (exact matches only)"
  task match_unknown: :environment do
    unknown_taxons = Taxon.unknown_taxon
    progressbar = ProgressBar.create(total: unknown_taxons.count, format: "%t: |%B| %c/%C (%E)")
    unknown_taxons.find_each do |taxon|
      taxon.set_gbif_id_from_match
      taxon.revision_comment = "Matched to GBIF Backbone Taxonomy"
      taxon.save!
      progressbar.increment
    end
  end

end

