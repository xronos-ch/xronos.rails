# frozen_string_literal: true

require 'test_helper'

class Site::WikidataMatchJobTest < ActiveJob::TestCase # rubocop:disable Style/ClassAndModuleChildren
  ENDPOINT = %r{\Ahttps://query\.wikidata\.org/sparql\?}

  test 'repeated lookups create one proposal per candidate and no linked resource' do
    site = create(:site, name: 'A "quoted" site')
    stub_request(:get, ENDPOINT).with do |request|
      URI.decode_www_form(request.uri.query).to_h.fetch('query').include?("#{site.name.to_json}@en")
    end.to_return(body: response_for(site.name, 'Q42', 'Q43'))

    assert_no_difference 'LinkedResource.count' do
      assert_difference 'CurationProposal.count', 2 do
        2.times { Site::WikidataMatchJob.perform_now([site.id]) }
      end
    end

    assert_equal %w[Q42 Q43], site.curation_proposals.order(:target_key).pluck(:target_key)
    assert_equal site.name, site.curation_proposals.first.evidence.fetch('site_name')
  end

  test 'existing links are skipped without contacting Wikidata' do
    site = create(:site)
    link = create(:linked_resource, linkable: site, source: 'Wikidata', external_id: 'Q42', status: :approved)
    request = stub_request(:get, ENDPOINT)

    assert_no_difference 'CurationProposal.count' do
      Site::WikidataMatchJob.perform_now([site.id])
    end

    assert_not_requested request
    assert_equal 'Q42', link.reload.external_id
  end

  test 'a failed lookup is retried and preserves current proposals' do
    site = create(:site)
    proposal = site.curation_proposals.create!(kind: Site::WikidataProposal::KIND, target_key: 'Q42',
                                               evidence: { site_name: site.name })
    stub_request(:get, ENDPOINT).to_return(status: 503)

    assert_enqueued_with(job: Site::WikidataMatchJob, args: [[site.id]]) do
      Site::WikidataMatchJob.perform_now([site.id])
    end

    assert_equal 'Q42', proposal.reload.target_key
    assert_nil site.wikidata_link
  end

  private

  def response_for(name, *qids)
    bindings = qids.map do |qid|
      { name: { value: name }, item: { value: "http://www.wikidata.org/entity/#{qid}" },
        itemLabel: { value: name }, itemDescription: { value: 'Archaeological site' } }
    end
    { results: { bindings: bindings } }.to_json
  end
end
