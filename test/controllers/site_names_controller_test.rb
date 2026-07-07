# frozen_string_literal: true

require 'test_helper'

class SiteNamesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[new create edit update destroy],
    param_key: :site_name,
    parent: { site_id: :smoke_site_id },
    statuses: {
      new: { not_signed_in: :redirect, signed_in: :success },
      create: { not_signed_in: :redirect, signed_in: :found },
      edit: { not_signed_in: :redirect, signed_in: :success },
      update: { not_signed_in: :redirect, signed_in: :found },
      destroy: { not_signed_in: :redirect, signed_in: :found }
    }
  )

  # Override smoke_record so it shares the same parent site as the
  # parent params (otherwise @site.site_names.find would 404).
  def smoke_record
    @smoke_record ||= create(:site_name, site_id: smoke_site_id)
  end

  def smoke_site_id
    @smoke_site_id ||= create(:site).id
  end

  # attributes_for(:site_name) returns {site: <Site>, ...}; the
  # controller's strong params accept site_id only via the parent URL
  # helper, not the body.
  def smoke_payload_for(_action)
    attributes_for(:site_name).except(:site)
  end

  test 'unauthenticated users cannot create site names' do
    site = create(:site)

    assert_no_difference('SiteName.count') do
      post site_site_names_path(site), params: {
        site_name: {
          name: 'Unauthorized Site Name'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end

  test 'unauthenticated users cannot update site names' do
    site_name = create(:site_name)
    original_name = site_name.name

    patch site_site_name_path(site_name.site, site_name), params: {
      site_name: {
        name: 'Changed Without Auth'
      }
    }

    assert_not_includes [200, 201, 204], response.status
    assert_equal original_name, site_name.reload.name
  end
end