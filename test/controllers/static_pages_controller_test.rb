require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "visitors can read the acknowledgements" do
    get acknowledgements_path
    assert_response :success
  end
end
