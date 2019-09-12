require 'test_helper'

class SitesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @site = FactoryBot.create(:site)
    @admin = FactoryBot.create(:user)
  end

  test "should get index" do
    get sites_url
    assert_response :success
  end

  test "should get new" do
    sign_in @admin
    get new_site_url
    assert_response :success
  end

  test "should create site" do
    sign_in @admin
    assert_difference('Site.count') do
      post sites_url, params: { site: { name: "Testsite1" } }
    end
    assert_redirected_to site_url(Site.last)
  end

  test "should show site" do
    get site_url(@site)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_site_url(@site)
    assert_response :success
  end

  test "should update site" do
    sign_in @admin
    patch site_url(@site), params: { site: { name: "Testsite2" } }
    assert_redirected_to site_url(@site)
  end

  test "should destroy site" do
    sign_in @admin
    assert_difference('Site.count', -1) do
      delete site_url(@site)
    end
    assert_redirected_to sites_url
  end

end
