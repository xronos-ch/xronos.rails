# frozen_string_literal: true

require 'test_helper'

class C14sControllerTest < ActionDispatch::IntegrationTest
  test 'downloads a C14 record as MIaaRD JSON' do
    site = Site.create!(
      name: 'Test Site',
      lat: 54.323,
      lng: 10.122,
      country_code: 'DE'
    )

    context = Context.create!(
      name: 'Test Context',
      site: site
    )

    taxon = Taxon.create!(
      name: 'Homo sapiens',
      gbif_id: 2_436_436
    )

    sample = Sample.create!(
      context: context,
      taxon: taxon
    )

    c14 = C14.create!(
      sample: sample,
      lab_identifier: 'OxA-12345',
      bp: 4500,
      std: 30,
      method: 'AMS'
    )

    get c14_path(c14, format: :json, schema: C14::MIAARD::SCHEMA)

    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)

    assert_equal 'oxa', json['lab_code']
    assert_equal '12345', json['lab_id']
    assert_equal 4500, json['conventional_age']
    assert_equal 30, json['conventional_age_error']
    assert_equal 'AMS', json['measurement_method']
    assert_equal 'gbif:2436436', json['sample_taxon_id']
  end

  test 'downloads C14 records as a MIaaRD collection' do
    site = Site.create!(name: 'Test Site')
    context = Context.create!(site: site)
    sample = Sample.create!(context: context)

    C14.create!(
      sample: sample,
      lab_identifier: 'OxA-12345',
      bp: 4500,
      std: 30
    )

    get c14s_path(format: :json, schema: C14::MIAARD::SCHEMA)

    assert_response :success
    assert_equal 'application/json', response.media_type

    json = JSON.parse(response.body)

    assert json.key?('entries')
    assert json['entries'].any?
    assert_equal 'oxa', json['entries'].first['lab_code']
  end

  test 'downloads filtered C14 records as a MIaaRD collection' do
    site = Site.create!(name: 'Test Site')
    context = Context.create!(site: site)
    sample = Sample.create!(context: context)

    matching = C14.create!(
      sample: sample,
      lab_identifier: 'OxA-12345',
      bp: 4500,
      std: 30
    )

    C14.create!(
      sample: sample,
      lab_identifier: 'Beta-67890',
      bp: 3200,
      std: 25
    )

    get c14s_path(
      format: :json,
      schema: C14::MIAARD::SCHEMA,
      c14: { lab_identifier: matching.lab_identifier }
    )

    assert_response :success

    json = JSON.parse(response.body)

    assert_equal 1, json['entries'].length
    assert_equal 'oxa', json['entries'].first['lab_code']
    assert_equal '12345', json['entries'].first['lab_id']
  end
end
