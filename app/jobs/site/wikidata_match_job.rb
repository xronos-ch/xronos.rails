# frozen_string_literal: true

class Site
  # Looks for Wikidata links outside web requests and records candidates for review.
  class WikidataMatchJob < ApplicationJob
    BATCH_SIZE = 25

    retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, BatchMatchableToWikidata::WikidataLookupFailed,
             wait: 1.minute, attempts: 3

    def perform(site_ids)
      sites = Site.missing_wikidata_link.where(id: site_ids).where.not(name: [nil, '']).to_a
      return if sites.empty?

      matches = Site.wikidata_match_candidates_batch(sites)
      sites.each { |site| WikidataProposal.record_matches(site, matches.fetch(site.name, [])) }
    end
  end
end
