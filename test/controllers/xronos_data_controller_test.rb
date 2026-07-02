# frozen_string_literal: true

# test/controllers/xronos_data_controller_test.rb

require 'test_helper'

class XronosDataControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
  end

  test 'data index responds successfully' do
    get data_path

    assert_response :success
  end

  test 'data json responds successfully' do
    get data_path(format: :json)

    assert_response :success
    assert_equal 'application/json', response.media_type
    assert_nothing_raised { JSON.parse(response.body) }
  end

  test 'data csv responds successfully' do
    get data_path(format: :csv)

    assert_response :success
    assert_includes response.media_type, 'text/csv'
  end

  test 'data geojson responds successfully' do
    get data_path(format: :geojson)

    assert_response :success
    assert_includes ['application/geo+json', 'application/json'], response.media_type
    assert_kind_of Array, JSON.parse(response.body)
  end

  test 'data miaard json responds successfully' do
    get data_path(format: :json, schema: C14::MIAARD::SCHEMA)

    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)

    assert_kind_of Hash, json
    assert json.key?('entries')
    assert_kind_of Array, json['entries']
  end

  test 'data geojson excludes sites without complete coordinates' do
    mapped_site = create(:site, name: 'Mapped Site', lat: 47.0, lng: 8.0)
    unmapped_site = create(:site, name: 'Unmapped Site', lat: nil, lng: nil)

    mapped_context = create(:context, site: mapped_site)
    unmapped_context = create(:context, site: unmapped_site)

    mapped_sample = create(:sample, context: mapped_context)
    unmapped_sample = create(:sample, context: unmapped_context)

    create(:c14, sample: mapped_sample)
    create(:c14, sample: unmapped_sample)

    get data_path(format: :geojson)

    assert_response :success
    assert_includes ['application/geo+json', 'application/json'], response.media_type

    features = JSON.parse(response.body)

    assert_kind_of Array, features

    names = features.map { |feature| feature.dig('properties', 'name') }

    assert_includes names, 'Mapped Site'
    assert_not_includes names, 'Unmapped Site'

    coordinates = features.map { |feature| feature.dig('geometry', 'coordinates') }

    assert(coordinates.all? { |coords| coords.is_a?(Array) && coords.size == 2 })
    assert(coordinates.all? { |coords| coords.none?(&:nil?) })
  end

  test 'data geojson returns an empty array when filtered sites have no coordinates' do
    site = create(:site, name: 'Only Unmapped GeoJSON Site', lat: nil, lng: nil)
    context = create(:context, site: site)
    sample = create(:sample, context: context)

    create(:c14, sample: sample)

    refresh_data_views

    get data_path(
          format: :geojson,
          params: {
            filter: {
              sites: {
                name: ['Only Unmapped GeoJSON Site']
              }
            }
          }
        )

    assert_response :success
    assert_includes ['application/geo+json', 'application/json'], response.media_type
    assert_equal [], JSON.parse(response.body)
  end

  test 'data json applies material filter' do
    included_material = create(:material, name: 'JSON Charcoal')
    excluded_material = create(:material, name: 'JSON Bone')

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(:c14, sample: included_sample, lab_identifier: 'JSON-Included-1')
    create(:c14, sample: excluded_sample, lab_identifier: 'JSON-Excluded-1')

    refresh_data_views

    get data_path(
          format: :json,
          params: material_filter_params('JSON Charcoal')
        )

    assert_response :success
    assert_equal 'application/json', response.media_type

    body = response.body

    assert_includes body, 'JSON-Included-1'
    assert_not_includes body, 'JSON-Excluded-1'
  end

  test 'data index applies material filter' do
    included_material = create(:material, name: 'HTML Charcoal')
    excluded_material = create(:material, name: 'HTML Bone')

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(:c14, sample: included_sample, lab_identifier: 'HTML-Included-1')
    create(:c14, sample: excluded_sample, lab_identifier: 'HTML-Excluded-1')

    refresh_data_views

    get data_path(
          params: material_filter_params('HTML Charcoal')
        )

    assert_response :success
    assert_includes response.body, 'HTML-Included-1'
    assert_not_includes response.body, 'HTML-Excluded-1'
  end

  test 'data csv includes only filtered records' do
    included_material = create(:material, name: 'CSV Charcoal')
    excluded_material = create(:material, name: 'CSV Bone')

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(:c14, sample: included_sample, lab_identifier: 'CSV-Included-1')
    create(:c14, sample: excluded_sample, lab_identifier: 'CSV-Excluded-1')

    refresh_data_views

    get data_path(
          format: :csv,
          params: material_filter_params('CSV Charcoal')
        )

    assert_response :success
    assert_includes response.media_type, 'text/csv'
    assert_includes response.body, 'CSV-Included-1'
    assert_not_includes response.body, 'CSV-Excluded-1'
  end

  test 'data miaard json includes only filtered records' do
    included_material = create(:material, name: 'MIaaRD Charcoal')
    excluded_material = create(:material, name: 'MIaaRD Bone')

    included_sample = create(:sample, material: included_material)
    excluded_sample = create(:sample, material: excluded_material)

    create(
      :c14,
      sample: included_sample,
      lab_identifier: 'OxA-12345',
      bp: 4500,
      std: 30
    )

    create(
      :c14,
      sample: excluded_sample,
      lab_identifier: 'Beta-67890',
      bp: 3200,
      std: 25
    )

    refresh_data_views

    get data_path(
          format: :json, schema: C14::MIAARD::SCHEMA,
          params: material_filter_params('MIaaRD Charcoal')
        )

    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)
    entries = json.fetch('entries')

    assert_equal 1, entries.length

    assert_equal 'OxA', entries.first['lab_code']
    assert_equal '12345', entries.first['lab_id']
    assert_equal 'MIaaRD Charcoal', entries.first['sample_material']
    assert_nil entries.first['sample_ids']

    exported_lab_ids = entries.map { |entry| [entry['lab_code'], entry['lab_id']] }

    assert_includes exported_lab_ids, ['OxA', '12345']
    assert_not_includes exported_lab_ids, ['Beta', '67890']
  end

  private

  def refresh_data_views
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW data_views')
  end

  def material_filter_params(material_name)
    {
      filter: {
        materials: {
          name: [material_name]
        }
      }
    }
  end
end