# frozen_string_literal: true

require 'test_helper'

class SiteNamesControllerTest < ActionDispatch::IntegrationTest
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