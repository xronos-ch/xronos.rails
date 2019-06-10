require 'test_helper'

class ArchObjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @arch_object = arch_objects(:one)
  end

  test "should get index" do
    get arch_objects_url
    assert_response :success
  end

  test "should get new" do
    get new_arch_object_url
    assert_response :success
  end

  test "should create arch_object" do
    assert_difference('ArchObject.count') do
      post arch_objects_url, params: { arch_object: {  } }
    end

    assert_redirected_to arch_object_url(ArchObject.last)
  end

  test "should show arch_object" do
    get arch_object_url(@arch_object)
    assert_response :success
  end

  test "should get edit" do
    get edit_arch_object_url(@arch_object)
    assert_response :success
  end

  test "should update arch_object" do
    patch arch_object_url(@arch_object), params: { arch_object: {  } }
    assert_redirected_to arch_object_url(@arch_object)
  end

  test "should destroy arch_object" do
    assert_difference('ArchObject.count', -1) do
      delete arch_object_url(@arch_object)
    end

    assert_redirected_to arch_objects_url
  end
end
