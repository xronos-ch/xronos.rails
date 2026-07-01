# frozen_string_literal: true

require 'test_helper'

class Sites::DescriptionsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  setup do
    Rails.cache.clear
    @site = FactoryBot.create(:site)
    @lod_link = FactoryBot.create(:lod_link,
                                  linkable: @site,
                                  source: 'Wikidata',
                                  external_id: 123,
                                  status: 'approved')
  end

  test 'show returns the populated frame' do
    description = Site::Description.new(lod_link: @lod_link)
    description.define_singleton_method(:data) {
      { wikipedia_title: 'Site', wikipedia_extract_text: 'Lead.', wikipedia_url: 'https://...',
        images: [], commons_category_url: nil, commons_category_title: nil }
    }
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
