# frozen_string_literal: true

require 'test_helper'

class SitesControllerTest < ActionDispatch::IntegrationTest
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
