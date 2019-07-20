require 'test_helper'

class TypochronologicalUnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @typochronological_unit = typochronological_units(:one)
  end

  test "should get index" do
    get typochronological_units_url
    assert_response :success
  end

  test "should get new" do
    get new_typochronological_unit_url
    assert_response :success
  end

  test "should create typochronological_unit" do
    assert_difference('TypochronologicalUnit.count') do
      post typochronological_units_url, params: { typochronological_unit: { approx_end_time: @typochronological_unit.approx_end_time, approx_start_time: @typochronological_unit.approx_start_time, name: @typochronological_unit.name } }
    end

    assert_redirected_to typochronological_unit_url(TypochronologicalUnit.last)
  end

  test "should show typochronological_unit" do
    get typochronological_unit_url(@typochronological_unit)
    assert_response :success
  end

  test "should get edit" do
    get edit_typochronological_unit_url(@typochronological_unit)
    assert_response :success
  end

  test "should update typochronological_unit" do
    patch typochronological_unit_url(@typochronological_unit), params: { typochronological_unit: { approx_end_time: @typochronological_unit.approx_end_time, approx_start_time: @typochronological_unit.approx_start_time, name: @typochronological_unit.name } }
    assert_redirected_to typochronological_unit_url(@typochronological_unit)
  end

  test "should destroy typochronological_unit" do
    assert_difference('TypochronologicalUnit.count', -1) do
      delete typochronological_unit_url(@typochronological_unit)
    end

    assert_redirected_to typochronological_units_url
  end
end
