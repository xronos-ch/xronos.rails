# test/integration/api/v1/get_data_test.rb

require "test_helper"

class Api::V1::GetDataTest < ActionDispatch::IntegrationTest
  setup do
    create_list(:c14, 10)
    DataView.refresh

    get "/api/v1/data"
  end

  test "returns all C14s" do
    assert_equal C14.count, json_response.size
  end

  test "returns status code 200" do
    assert_response :success
  end

  test "matches API v1 schema" do
    assert_equal C14.count, json_response.count
    assert_matches_response_schema "apiv1", json_response
  end

  test "processes a date without site types" do
    c14 = build(:c14)
    c14.sample.context.site.site_types = []
    c14.save!

    DataView.refresh

    get "/api/v1/data"

    assert_response :success
  end
end