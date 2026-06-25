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

  test "data json applies material filter" do
    Rails.cache.clear

    included_material = create(:material, name: "Charcoal")
    excluded_material = create(:material, name: "Bone")

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(:c14, sample: included_sample, lab_identifier: "Included-1")
    create(:c14, sample: excluded_sample, lab_identifier: "Excluded-1")

    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW data_views")

    get data_path(
          format: :json,
          params: {
            filter: {
              materials: {
                name: ["Charcoal"]
              }
            }
          }
        )

    assert_response :success

    body = response.body

    assert_includes body, "Included-1"
    assert_not_includes body, "Excluded-1"
  end

  test "data geojson returns an empty array when no sites have coordinates" do
    Rails.cache.clear

    site = create(:site, name: "Unmapped Site", lat: nil, lng: nil)
    context = create(:context, site: site)
    sample = create(:sample, context: context)
    create(:c14, sample: sample)

    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW data_views")

    get data_path(format: :geojson)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "data index responds successfully with material filter" do
    material = create(:material, name: "Charcoal")
    sample = create(:sample, material: material)
    create(:c14, sample: sample)

    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW data_views")

    get data_path(
          params: {
            filter: {
              materials: {
                name: ["Charcoal"]
              }
            }
          }
        )

    assert_response :success
  end

  test "data csv includes only filtered records" do
    included_material = create(:material, name: "Charcoal")
    excluded_material = create(:material, name: "Bone")

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(:c14, sample: included_sample, lab_identifier: "CSV-Included-1")
    create(:c14, sample: excluded_sample, lab_identifier: "CSV-Excluded-1")

    ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW data_views")

    get data_path(
          format: :csv,
          params: {
            filter: {
              materials: {
                name: ["Charcoal"]
              }
            }
          }
        )

    assert_response :success
    assert_includes response.body, "CSV-Included-1"
    assert_not_includes response.body, "CSV-Excluded-1"
  end

end