# frozen_string_literal: true

require 'test_helper'

class C14sControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  test 'show redirects to the canonical record when the C14 is superseded' do
    site = create(:site)
    context = create(:context, site: site)
    sample = create(:sample, context: context)
    canonical = create(:c14, sample: sample)
    superseded = create(:c14, :superseded_by, canonical: canonical, sample: sample)

    get c14_path(superseded)

    assert_response :moved_permanently
    assert_equal c14_url(canonical), response.location
  end

  test 'show follows a re-pointed chain to the canonical' do
    site = create(:site)
    context = create(:context, site: site)
    sample = create(:sample, context: context)
    canonical = create(:c14, sample: sample)
    middle = create(:c14, sample: sample)
    leaf = create(:c14, sample: sample)

    leaf.supersede!(middle)
    middle.supersede!(canonical)

    get c14_path(leaf)

    assert_response :moved_permanently
    assert_equal c14_url(canonical), response.location
  end

test 'downloads a C14 record as MIaaRD JSON' do
    site = create(
      :site,
      name: 'Test Site',
      lat: 54.323,
      lng: 10.122,
      country_code: 'DE'
    )

    context = create(
      :context,
      name: 'Test Context',
      site: site
    )

    taxon = create(
      :taxon,
      name: 'Homo sapiens',
      gbif_id: 2_436_436
    )

    sample = create(
      :sample,
      context: context,
      taxon: taxon
    )

    c14 = create(
      :c14,
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

    assert_equal 'OxA', json['lab_code']
    assert_equal '12345', json['lab_id']
    assert_equal 4500, json['conventional_age']
    assert_equal 30, json['conventional_age_error']
    assert_equal 'AMS', json['measurement_method']
    assert_equal 'gbif:2436436', json['sample_taxon_id']
  end

  test 'downloads C14 records as a MIaaRD collection' do
    site = create(:site, name: 'Test Site')
    context = create(:context, site: site)
    sample = create(:sample, context: context)

    create(
      :c14,
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
    assert_equal 'OxA', json['entries'].first['lab_code']
  end

  test 'downloads filtered C14 records as a MIaaRD collection' do
    site = create(:site, name: 'Test Site')
    context = create(:context, site: site)
    sample = create(:sample, context: context)

    matching = create(
      :c14,
      sample: sample,
      lab_identifier: 'OxA-12345',
      bp: 4500,
      std: 30
    )

    create(
      :c14,
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
    assert_equal 'OxA', json['entries'].first['lab_code']
    assert_equal '12345', json['entries'].first['lab_id']
  end
end