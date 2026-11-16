# frozen_string_literal: true

namespace :cache do
  desc 'Queue Wikidata proposal lookups for sites without a Wikidata link (optional SITE_IDS=12,34)'
  task update_sites_wikidata_match: :environment do
    if ENV.key?('SITE_IDS')
      ids = ENV.fetch('SITE_IDS').split(',', -1).map(&:strip)
      abort 'SITE_IDS must contain comma-separated positive site IDs.' unless ids.any? && ids.all?(/\A[1-9][0-9]*\z/)
    end

    job_count, site_count = Site::WikidataBatchJob.enqueue_matches(site_ids: ids)
    puts "Queued #{job_count} Wikidata lookup job(s) for #{site_count} site(s)."
  rescue ActiveJob::EnqueueError => e
    abort e.message
  end
end
