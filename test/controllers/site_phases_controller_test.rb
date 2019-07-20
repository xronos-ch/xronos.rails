require 'test_helper'

class SitePhasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site_phase = site_phases(:one)
  end

  test "should get index" do
    get site_phases_url
    assert_response :success
  end

  test "should get new" do
    get new_site_phase_url
    assert_response :success
  end

  test "should create site_phase" do
    assert_difference('SitePhase.count') do
      post site_phases_url, params: { site_phase: { approx_end_time: @site_phase.approx_end_time, approx_start_time: @site_phase.approx_start_time, name: @site_phase.name } }
    end

    assert_redirected_to site_phase_url(SitePhase.last)
  end

  test "should show site_phase" do
    get site_phase_url(@site_phase)
    assert_response :success
  end

  test "should get edit" do
    get edit_site_phase_url(@site_phase)
    assert_response :success
  end

  test "should update site_phase" do
    patch site_phase_url(@site_phase), params: { site_phase: { approx_end_time: @site_phase.approx_end_time, approx_start_time: @site_phase.approx_start_time, name: @site_phase.name } }
    assert_redirected_to site_phase_url(@site_phase)
  end

  test "should destroy site_phase" do
    assert_difference('SitePhase.count', -1) do
      delete site_phase_url(@site_phase)
    end

    assert_redirected_to site_phases_url
  end
end
