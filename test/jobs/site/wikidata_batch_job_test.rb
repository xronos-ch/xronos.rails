# frozen_string_literal: true

require 'test_helper'

class WikidataBatchJobTest < ActiveJob::TestCase
  test 'the scheduled job staggers batches of sites eligible for Wikidata lookup' do
    sites = create_list(:site, Site::WikidataMatchJob::BATCH_SIZE + 1)
    linked = create(:site)
    create(:linked_resource, linkable: linked, source: 'Wikidata', external_id: 'Q1', status: :approved)

    freeze_time do
      assert_enqueued_jobs 2, only: Site::WikidataMatchJob do
        assert_enqueued_with(job: Site::WikidataMatchJob, args: [sites[0...-1].map(&:id)], at: Time.current) do
          Site::WikidataBatchJob.perform_now
        end
      end
      assert_enqueued_with(job: Site::WikidataMatchJob, args: [[sites.last.id]], at: 5.seconds.from_now)
    end
  end
end
