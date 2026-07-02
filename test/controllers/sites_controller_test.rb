# frozen_string_literal: true

require 'test_helper'

class SitesControllerTest < ActionDispatch::IntegrationTest
  test 'show redirects to the canonical record when the site is superseded' do
    canonical = create(:site)
    superseded = create(:site, :superseded, superseded_by_site: canonical)

    get site_path(superseded)

    assert_response :moved_permanently
    assert_equal site_url(canonical), response.location
  end

  test 'show follows a multi-link superseded chain to the canonical' do
    canonical = create(:site)
    middle = create(:site, :superseded, superseded_by_site: canonical)
    leaf = create(:site, :superseded, superseded_by_site: middle)

    get site_path(leaf)

    assert_response :moved_permanently
    assert_equal site_url(canonical), response.location
  end

  test 'show renders normally for a non-superseded site' do
    site = create(:site)

    get site_path(site)

    assert_response :success
  end
end
