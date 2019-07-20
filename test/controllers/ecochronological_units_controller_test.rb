require 'test_helper'

class EcochronologicalUnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ecochronological_unit = ecochronological_units(:one)
  end

  test "should get index" do
    get ecochronological_units_url
    assert_response :success
  end

  test "should get new" do
    get new_ecochronological_unit_url
    assert_response :success
  end

  test "should create ecochronological_unit" do
    assert_difference('EcochronologicalUnit.count') do
      post ecochronological_units_url, params: { ecochronological_unit: { approx_end_time: @ecochronological_unit.approx_end_time, approx_start_time: @ecochronological_unit.approx_start_time, name: @ecochronological_unit.name } }
    end

    assert_redirected_to ecochronological_unit_url(EcochronologicalUnit.last)
  end

  test "should show ecochronological_unit" do
    get ecochronological_unit_url(@ecochronological_unit)
    assert_response :success
  end

  test "should get edit" do
    get edit_ecochronological_unit_url(@ecochronological_unit)
    assert_response :success
  end

  test "should update ecochronological_unit" do
    patch ecochronological_unit_url(@ecochronological_unit), params: { ecochronological_unit: { approx_end_time: @ecochronological_unit.approx_end_time, approx_start_time: @ecochronological_unit.approx_start_time, name: @ecochronological_unit.name } }
    assert_redirected_to ecochronological_unit_url(@ecochronological_unit)
  end

  test "should destroy ecochronological_unit" do
    assert_difference('EcochronologicalUnit.count', -1) do
      delete ecochronological_unit_url(@ecochronological_unit)
    end

    assert_redirected_to ecochronological_units_url
  end
end
