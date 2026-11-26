# frozen_string_literal: true

require 'test_helper'
require 'rake'

class WikidataBatchTest < ActiveJob::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?('cache:update_sites_wikidata_match')
    @task = Rake::Task['cache:update_sites_wikidata_match']
    @task.reenable
    @previous_site_ids = ENV['SITE_IDS']
  end

  teardown do
    ENV['SITE_IDS'] = @previous_site_ids
  end

  test 'a targeted batch queues two sites and produces proposals in one request' do
    first, second = create_list(:site, 2)
    linked = create(:site)
    create(:linked_resource, linkable: linked, source: 'Wikidata', external_id: 'Q1', status: :approved)
    unrelated = create(:site)
    ENV['SITE_IDS'] = [first.id, linked.id, second.id, first.id].join(',')
    request = stub_request(:get, %r{\Ahttps://query\.wikidata\.org/sparql\?})
              .with { |http_request| query_covers?(http_request, first, second, linked, unrelated) }
              .to_return(body: response_for(first, second))

    assert_enqueued_jobs 1, only: Site::WikidataMatchJob do
      stdout, = capture_io { @task.invoke }
      assert_includes stdout, 'Queued 1 Wikidata lookup job(s) for 2 site(s).'
    end
    assert_not_requested request
    assert_no_difference 'LinkedResource.count' do
      perform_enqueued_jobs(only: Site::WikidataMatchJob)
    end

    assert_requested request, times: 1
    assert_equal [first.id, second.id], Site::WikidataProposal.for_review.order(:subject_id).pluck(:subject_id)
  end

  test 'an empty selection never falls through to the full batch' do
    create(:site)
    ENV['SITE_IDS'] = ''

    assert_no_enqueued_jobs only: Site::WikidataMatchJob do
      _, stderr = capture_io { assert_raises(SystemExit) { @task.invoke } }
      assert_includes stderr, 'SITE_IDS must contain'
    end
  end

  private

  def query_covers?(request, first, second, linked, unrelated)
    query = URI.decode_www_form(request.uri.query).to_h.fetch('query')
    [first, second].all? { |site| query.include?("#{site.name.to_json}@en") } &&
      [linked, unrelated].none? { |site| query.include?("#{site.name.to_json}@en") }
  end

  def response_for(*sites)
    bindings = sites.each_with_index.map do |site, index|
      { name: { value: site.name }, item: { value: "http://www.wikidata.org/entity/Q#{42 + index}" } }
    end
    { results: { bindings: bindings } }.to_json
  end
end
