require 'test_helper'

class FellPhasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fell_phase = fell_phases(:one)
  end

  test "should get index" do
    get fell_phases_url
    assert_response :success
  end

  test "should get new" do
    get new_fell_phase_url
    assert_response :success
  end

  test "should create fell_phase" do
    assert_difference('FellPhase.count') do
      post fell_phases_url, params: { fell_phase: { end_time: @fell_phase.end_time, name: @fell_phase.name, site_id: @fell_phase.site_id, start_time: @fell_phase.start_time } }
    end

    assert_redirected_to fell_phase_url(FellPhase.last)
  end

  test "should show fell_phase" do
    get fell_phase_url(@fell_phase)
    assert_response :success
  end

  test "should get edit" do
    get edit_fell_phase_url(@fell_phase)
    assert_response :success
  end

  test "should update fell_phase" do
    patch fell_phase_url(@fell_phase), params: { fell_phase: { end_time: @fell_phase.end_time, name: @fell_phase.name, site_id: @fell_phase.site_id, start_time: @fell_phase.start_time } }
    assert_redirected_to fell_phase_url(@fell_phase)
  end

  test "should destroy fell_phase" do
    assert_difference('FellPhase.count', -1) do
      delete fell_phase_url(@fell_phase)
    end

    assert_redirected_to fell_phases_url
  end
end
