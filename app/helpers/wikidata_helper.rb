##
# Helper methods for Wikidata 
module WikidataHelper

  ##
  # Looks for Wikidata matches for a site
  def wikidata_matches_for(site)
    Site.wikidata_match_candidates_batch([site])
  end

end
