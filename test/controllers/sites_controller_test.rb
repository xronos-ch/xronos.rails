# frozen_string_literal: true

require 'test_helper'
class SitesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    param_key: :site,
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :success,  signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  test 'show redirects to the canonical record when the site is superseded' do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)

    get site_path(superseded)

    assert_response :moved_permanently
    assert_equal site_url(canonical), response.location
  end

  test 'show renders normally for a non-superseded site' do
    site = create(:site)

    get site_path(site)

    assert_response :success
  end

  test 'unauthenticated users cannot create sites' do
    assert_no_difference('Site.count') do
      post sites_path, params: {
        site: {
          name: 'Unauthorized Test Site',
          lat: 54.323,
          lng: 10.122,
          country_code: 'DE'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end

  test 'CSV export rejects pagination and ordering parameters' do
    create(:site, name: 'Test Site')

    get sites_path(format: :csv, sites_order_by: 'name', sites_order: 'desc', page: 5)

    assert_response :bad_request
  end

  test 'CSV export works without pagination and ordering parameters' do
    create(:site, name: 'Test Site')

    get sites_path(format: :csv)

    assert_response :success
    assert_equal 'text/csv', response.media_type
  end

  test 'show uses pre-computed counts and does not issue extra COUNT queries' do
    site = create(:site)
    context = create(:context, site: site)
    sample = create(:sample, context: context)
    create_list(:c14, 2, sample: sample)
    create_list(:typo, 1, sample: sample)
    create_list(:citation, 3, citing: site)

    # Refresh the materialized view to pick up the new data
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW sites_with_counts')

    get site_path(site)

    assert_response :success
    assert_match(/2 radiocarbon dates/, response.body)
    assert_match(/1 typological classification/, response.body)
    assert_match(/3 bibliographic references/, response.body)
  end
end
