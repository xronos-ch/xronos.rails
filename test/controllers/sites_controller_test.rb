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
end
