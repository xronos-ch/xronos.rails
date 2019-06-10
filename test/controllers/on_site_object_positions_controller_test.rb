require 'test_helper'

class OnSiteObjectPositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @on_site_object_position = on_site_object_positions(:one)
  end

  test "should get index" do
    get on_site_object_positions_url
    assert_response :success
  end

  test "should get new" do
    get new_on_site_object_position_url
    assert_response :success
  end

  test "should create on_site_object_position" do
    assert_difference('OnSiteObjectPosition.count') do
      post on_site_object_positions_url, params: { on_site_object_position: { coord_X: @on_site_object_position.coord_X, coord_Y: @on_site_object_position.coord_Y, coord_Z: @on_site_object_position.coord_Z, coord_reference_system: @on_site_object_position.coord_reference_system, feature: @on_site_object_position.feature, site_grid_square: @on_site_object_position.site_grid_square } }
    end

    assert_redirected_to on_site_object_position_url(OnSiteObjectPosition.last)
  end

  test "should show on_site_object_position" do
    get on_site_object_position_url(@on_site_object_position)
    assert_response :success
  end

  test "should get edit" do
    get edit_on_site_object_position_url(@on_site_object_position)
    assert_response :success
  end

  test "should update on_site_object_position" do
    patch on_site_object_position_url(@on_site_object_position), params: { on_site_object_position: { coord_X: @on_site_object_position.coord_X, coord_Y: @on_site_object_position.coord_Y, coord_Z: @on_site_object_position.coord_Z, coord_reference_system: @on_site_object_position.coord_reference_system, feature: @on_site_object_position.feature, site_grid_square: @on_site_object_position.site_grid_square } }
    assert_redirected_to on_site_object_position_url(@on_site_object_position)
  end

  test "should destroy on_site_object_position" do
    assert_difference('OnSiteObjectPosition.count', -1) do
      delete on_site_object_position_url(@on_site_object_position)
    end

    assert_redirected_to on_site_object_positions_url
  end
end
