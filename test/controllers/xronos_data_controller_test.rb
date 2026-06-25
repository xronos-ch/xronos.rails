# test/controllers/xronos_data_controller_test.rb

require "test_helper"

class XronosDataControllerTest < ActionDispatch::IntegrationTest
  test "data index responds successfully" do
    get data_path
    assert_response :success
  end

  test "data json responds successfully" do
    get data_path(format: :json)
    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "data csv responds successfully" do
    get data_path(format: :csv)
    assert_response :success
    assert_includes response.media_type, "text/csv"
  end

  test "data geojson responds successfully" do
    get data_path(format: :geojson)
    assert_response :success
  end

  test "data geojson excludes sites without complete coordinates" do
    Rails.cache.clear

    mapped_site = create(:site, name: "Mapped Site", lat: 47.0, lng: 8.0)
    unmapped_site = create(:site, name: "Unmapped Site", lat: nil, lng: nil)

    mapped_context = create(:context, site: mapped_site)
    unmapped_context = create(:context, site: unmapped_site)

    mapped_sample = create(:sample, context: mapped_context)
    unmapped_sample = create(:sample, context: unmapped_context)

    create(:c14, sample: mapped_sample)
    create(:c14, sample: unmapped_sample)

    get data_path(format: :geojson)

    assert_response :success
    assert_not_equal "text/html", response.media_type

    features = JSON.parse(response.body)

    assert_kind_of Array, features

    names = features.map { |feature| feature.dig("properties", "name") }

    assert_includes names, "Mapped Site"
    assert_not_includes names, "Unmapped Site"

    coordinates = features.map { |feature| feature.dig("geometry", "coordinates") }

    assert coordinates.all? { |coords| coords.is_a?(Array) && coords.size == 2 }
    assert coordinates.all? { |coords| coords.none?(&:nil?) }
  end
end