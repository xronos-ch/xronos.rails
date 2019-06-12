require 'test_helper'

class DendroMeasurementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dendro_measurement = dendro_measurements(:one)
  end

  test "should get index" do
    get dendro_measurements_url
    assert_response :success
  end

  test "should get new" do
    get new_dendro_measurement_url
    assert_response :success
  end

  test "should create dendro_measurement" do
    assert_difference('DendroMeasurement.count') do
      post dendro_measurements_url, params: { dendro_measurement: { age: @dendro_measurement.age, dating_quality_estimation_category: @dendro_measurement.dating_quality_estimation_category, end_age_deviation: @dendro_measurement.end_age_deviation, start_age_deviation: @dendro_measurement.start_age_deviation } }
    end

    assert_redirected_to dendro_measurement_url(DendroMeasurement.last)
  end

  test "should show dendro_measurement" do
    get dendro_measurement_url(@dendro_measurement)
    assert_response :success
  end

  test "should get edit" do
    get edit_dendro_measurement_url(@dendro_measurement)
    assert_response :success
  end

  test "should update dendro_measurement" do
    patch dendro_measurement_url(@dendro_measurement), params: { dendro_measurement: { age: @dendro_measurement.age, dating_quality_estimation_category: @dendro_measurement.dating_quality_estimation_category, end_age_deviation: @dendro_measurement.end_age_deviation, start_age_deviation: @dendro_measurement.start_age_deviation } }
    assert_redirected_to dendro_measurement_url(@dendro_measurement)
  end

  test "should destroy dendro_measurement" do
    assert_difference('DendroMeasurement.count', -1) do
      delete dendro_measurement_url(@dendro_measurement)
    end

    assert_redirected_to dendro_measurements_url
  end
end
