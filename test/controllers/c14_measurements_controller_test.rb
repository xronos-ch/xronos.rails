require 'test_helper'

class C14MeasurementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @c14_measurement = c14_measurements(:one)
  end

  test "should get index" do
    get c14_measurements_url
    assert_response :success
  end

  test "should get new" do
    get new_c14_measurement_url
    assert_response :success
  end

  test "should create c14_measurement" do
    assert_difference('C14Measurement.count') do
      post c14_measurements_url, params: { c14_measurement: { bp: @c14_measurement.bp, cal_bp: @c14_measurement.cal_bp, cal_std: @c14_measurement.cal_std, delta_c13: @c14_measurement.delta_c13, delta_c13_std: @c14_measurement.delta_c13_std, method: @c14_measurement.method, std: @c14_measurement.std } }
    end

    assert_redirected_to c14_measurement_url(C14Measurement.last)
  end

  test "should show c14_measurement" do
    get c14_measurement_url(@c14_measurement)
    assert_response :success
  end

  test "should get edit" do
    get edit_c14_measurement_url(@c14_measurement)
    assert_response :success
  end

  test "should update c14_measurement" do
    patch c14_measurement_url(@c14_measurement), params: { c14_measurement: { bp: @c14_measurement.bp, cal_bp: @c14_measurement.cal_bp, cal_std: @c14_measurement.cal_std, delta_c13: @c14_measurement.delta_c13, delta_c13_std: @c14_measurement.delta_c13_std, method: @c14_measurement.method, std: @c14_measurement.std } }
    assert_redirected_to c14_measurement_url(@c14_measurement)
  end

  test "should destroy c14_measurement" do
    assert_difference('C14Measurement.count', -1) do
      delete c14_measurement_url(@c14_measurement)
    end

    assert_redirected_to c14_measurements_url
  end
end
