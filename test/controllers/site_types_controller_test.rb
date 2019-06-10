require 'test_helper'

class SiteTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site_type = site_types(:one)
  end

  test "should get index" do
    get site_types_url
    assert_response :success
  end

  test "should get new" do
    get new_site_type_url
    assert_response :success
  end

  test "should create site_type" do
    assert_difference('SiteType.count') do
      post site_types_url, params: { site_type: { description: @site_type.description, name: @site_type.name } }
    end

    assert_redirected_to site_type_url(SiteType.last)
  end

  test "should show site_type" do
    get site_type_url(@site_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_site_type_url(@site_type)
    assert_response :success
  end

  test "should update site_type" do
    patch site_type_url(@site_type), params: { site_type: { description: @site_type.description, name: @site_type.name } }
    assert_redirected_to site_type_url(@site_type)
  end

  test "should destroy site_type" do
    assert_difference('SiteType.count', -1) do
      delete site_type_url(@site_type)
    end

    assert_redirected_to site_types_url
  end
end
