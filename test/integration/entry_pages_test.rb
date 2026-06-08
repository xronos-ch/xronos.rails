require "test_helper"

class EntryPagesTest < ActionDispatch::IntegrationTest
  test "root page responds successfully" do
    get root_path

    assert_response :success
  end
end
