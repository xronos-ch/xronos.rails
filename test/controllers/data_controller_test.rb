require 'test_helper'

class DataControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get data_index_url
    assert_response :success
  end

end
