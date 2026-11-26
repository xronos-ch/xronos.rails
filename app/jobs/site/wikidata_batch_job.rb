# frozen_string_literal: true

class Site
  # Staggers periodic lookups so the full catalogue does not hit Wikidata at once.
  class WikidataBatchJob < ApplicationJob
    BATCH_INTERVAL = 5.seconds

    def self.enqueue_matches(site_ids: nil, interval: nil)
      sites = Site.missing_wikidata_link.where.not(name: [nil, ''])
      sites = sites.where(id: site_ids) unless site_ids.nil?

      job_count = site_count = 0
      sites.in_batches(of: WikidataMatchJob::BATCH_SIZE).each_with_index do |batch, index|
        ids = batch.ids.sort
        enqueue_match(ids, interval && interval * index)
        site_count += ids.size
        job_count += 1
      end
      [job_count, site_count]
    end

    def perform
      self.class.enqueue_matches(interval: BATCH_INTERVAL)
    end

    def self.enqueue_match(ids, delay)
      job = WikidataMatchJob.set(wait: delay).perform_later(ids)
      raise ActiveJob::EnqueueError, 'Could not enqueue a Wikidata lookup.' unless job
    end
    private_class_method :enqueue_match
  end
end
