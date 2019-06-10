require 'test_helper'

class FeatureTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feature_type = feature_types(:one)
  end

  test "should get index" do
    get feature_types_url
    assert_response :success
  end

  test "should get new" do
    get new_feature_type_url
    assert_response :success
  end

  test "should create feature_type" do
    assert_difference('FeatureType.count') do
      post feature_types_url, params: { feature_type: { description: @feature_type.description, name: @feature_type.name } }
    end

    assert_redirected_to feature_type_url(FeatureType.last)
  end

  test "should show feature_type" do
    get feature_type_url(@feature_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_feature_type_url(@feature_type)
    assert_response :success
  end

  test "should update feature_type" do
    patch feature_type_url(@feature_type), params: { feature_type: { description: @feature_type.description, name: @feature_type.name } }
    assert_redirected_to feature_type_url(@feature_type)
  end

  test "should destroy feature_type" do
    assert_difference('FeatureType.count', -1) do
      delete feature_type_url(@feature_type)
    end

    assert_redirected_to feature_types_url
  end
end
