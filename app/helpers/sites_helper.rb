module SitesHelper
  include DataTableHelper
  
  def wikidata_matches_for(site)
    Site.wikidata_match_candidates_batch([site])
  end
end
