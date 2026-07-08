# frozen_string_literal: true

require 'test_helper'

class Sites::DescriptionsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[show],
    query_params: { site_id: :smoke_site_id },
    statuses: {
      show: { not_signed_in: :success, signed_in: :success }
    }
  )

  def smoke_site_id
    @smoke_site_id ||= begin
      site = create(:site)
      create(:linked_resource, linkable: site, source: 'Wikidata', external_id: 'Q123', status: 'approved')
      site.id
    end
  end

  setup do
    Rails.cache.clear
    @site = FactoryBot.create(:site)
    @linked_resource = FactoryBot.create(:linked_resource,
                                         linkable: @site,
                                         source: 'Wikidata',
                                         external_id: 'Q123',
                                         status: 'approved')

    # The action fetches from Wikidata/Wikipedia. Stub the network
    # calls so the smoke test is deterministic and isolated.
    stub_request(:get, /wikidata\.org/).to_return(status: 200, body: '{}')
    stub_request(:get, /wikipedia\.org/).to_return(status: 200, body: '{}')
  end

  test 'show returns the populated frame' do
    description = Site::Description.new(linked_resource: @linked_resource)
    description.define_singleton_method(:data) do
      { wikipedia_title: 'Site', wikipedia_extract_text: 'Lead.', wikipedia_url: 'https://...',
        images: [], commons_category_url: nil, commons_category_title: nil }
    end
    description.define_singleton_method(:fetched_at) { Time.zone.local(2026, 6, 30) }

    Site::Description.stub :new, description do
      get site_description_path(@site)
    end

    assert_response :success
    assert_match '<turbo-frame', @response.body
    assert_match "id=\"#{ActionView::RecordIdentifier.dom_id(@site, :description)}\"", @response.body
    assert_match 'site-description-content', @response.body
  end

  test 'show returns 404 when the site is missing' do
    get '/sites/0/description'
    assert_response :not_found
  end
end
