require "test_helper"

class TaxonUsagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @id = 2877951
    @url = "https://api.gbif.org/v1/species/#{@id}"

    @response_body = {
      "canonicalName" => "Quercus robur",
      "rank" => "SPECIES",
      "authorship" => "L."
    }
  end

  #
  # basic success case
  #
  test "renders usage for valid GBIF id" do
    stub_request(:get, @url)
      .to_return(status: 200, body: @response_body.to_json)

    get taxon_usage_path(@id)

    assert_response :success
    assert_includes @response.body, "Quercus robur"
  end

  #
  # ensures correct endpoint is called
  #
  test "calls GBIF species endpoint" do
    stub_request(:get, @url)
      .to_return(status: 200, body: @response_body.to_json)

    get taxon_usage_path(@id)

    assert_requested :get, @url, times: 1
  end

  #
  # caching: repeated requests hit GBIF only once
  #
  test "reuses cached GBIF response across requests" do
    stub_request(:get, @url)
      .to_return(status: 200, body: @response_body.to_json)

    get taxon_usage_path(@id)
    get taxon_usage_path(@id)

    assert_requested :get, @url, times: 1
  end

  #
  # missing fields handled gracefully
  #
  test "renders successfully with incomplete GBIF data" do
    stub_request(:get, @url)
      .to_return(status: 200, body: {}.to_json)

    get taxon_usage_path(@id)

    assert_response :success
  end

  #
  # API failure handled gracefully
  #
  test "renders successfully when GBIF request fails" do
    stub_request(:get, @url)
      .to_return(status: 500)

    get taxon_usage_path(@id)

    assert_response :success
  end

  #
  # timeout handling
  #
  test "renders successfully when GBIF request times out" do
    stub_request(:get, @url).to_timeout

    get taxon_usage_path(@id)

    assert_response :success
  end

  #
  # correct content type for Turbo frames
  #
  test "responds with HTML suitable for turbo frame rendering" do
    stub_request(:get, @url)
      .to_return(status: 200, body: @response_body.to_json)

    get taxon_usage_path(@id)

    assert_equal "text/html; charset=utf-8", @response.media_type + "; charset=utf-8"
  end
end

