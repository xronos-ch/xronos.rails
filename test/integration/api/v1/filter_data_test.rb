# test/integration/api/v1/filter_data_test.rb

require "test_helper"

class Api::V1::FilterDataTest < ActionDispatch::IntegrationTest
  setup do
    @c14s = create_list(:c14, 10)
    DataView.refresh
  end

  test "query_labnr returns only C14s with that lab identifier" do
    labnr = @c14s.first.lab_identifier.to_s

    get "/api/v1/data", params: { query_labnr: labnr }

    assert_response :success
    assert_equal C14.where(lab_identifier: labnr).count, json_response.size

    labnrs = json_response.map { |entry| entry.dig("measurement", "labnr") }.uniq
    assert_equal 1, labnrs.length
    assert_includes labnrs, labnr
  end

  test "query_site returns only C14s with that site name" do
    site = @c14s.first.site.name

    get "/api/v1/data", params: { query_site: site }

    assert_response :success
    assert_equal C14.includes(sample: { context: :site }).where(site: { name: site }).count, json_response.size

    sites = json_response.map { |entry| entry.dig("measurement", "site") }.uniq
    assert_equal 1, sites.length
    assert_includes sites, site
  end

  test "query_site_type returns only C14s with that site type" do
    site_type = @c14s.first.site.site_types.first.name

    get "/api/v1/data", params: { query_site_type: site_type }

    assert_response :success
    assert_equal C14.includes(sample: { context: { site: :site_types } }).where(site_types: { name: site_type }).count, json_response.size

    site_types = json_response.map { |entry| entry.dig("measurement", "site_type") }.uniq
    assert_equal 1, site_types.length
    assert_includes site_types.to_s, site_type
  end

  test "query_country returns only C14s with that country" do
    country = @c14s.first.site.country_code

    get "/api/v1/data", params: { query_country: country }

    assert_response :success
    assert_equal C14.includes(sample: { context: :site }).where(site: { country_code: country }).count, json_response.size

    countries = json_response.map { |entry| entry.dig("measurement", "country") }.uniq
    assert_equal 1, countries.length
    assert_includes countries, country
  end

  test "query_feature returns only C14s with that feature" do
    feature = @c14s.first.context.name

    get "/api/v1/data", params: { query_feature: feature }

    assert_response :success
    assert_equal C14.includes(sample: :context).where(context: { name: feature }).count, json_response.size

    features = json_response.map { |entry| entry.dig("measurement", "feature") }.uniq
    assert_equal 1, features.length
    assert_includes features, feature
  end

  test "query_material returns only C14s with that material" do
    material = @c14s.first.sample.material.name

    get "/api/v1/data", params: { query_material: material }

    assert_response :success
    assert_equal C14.includes(sample: :material).where(sample: { materials: { name: material } }).count, json_response.size

    materials = json_response.map { |entry| entry.dig("measurement", "material") }.uniq
    assert_equal 1, materials.length
    assert_includes materials, material
  end

  test "query_species returns only C14s with that species" do
    species = @c14s.first.sample.taxon.name

    get "/api/v1/data", params: { query_species: species }

    assert_response :success
    assert_equal C14.includes(sample: :taxon).where(sample: { taxons: { name: species } }).count, json_response.size

    taxa = json_response.map { |entry| entry.dig("measurement", "species") }.uniq
    assert_equal 1, taxa.length
    assert_includes taxa, species
  end

  test "query_species with pipe returns C14s with either species" do
    species = @c14s.first.sample.taxon.name
    species2 = @c14s.second.sample.taxon.name

    get "/api/v1/data", params: { query_species: "#{species}|#{species2}" }

    assert_response :success
    assert_equal C14.includes(sample: :taxon).where(sample: { taxons: { name: [species, species2] } }).count, json_response.size

    taxa = json_response.map { |entry| entry.dig("measurement", "species") }.uniq
    assert_equal 2, taxa.length
    assert_includes taxa, species
    assert_includes taxa, species2
  end

  test "query_labnr and query_species returns C14s matching both" do
    labnr = @c14s.first.lab_identifier.to_s
    species = @c14s.first.sample.taxon.name

    get "/api/v1/data", params: {
      query_species: species,
      query_labnr: labnr
    }

    assert_response :success
    assert_equal C14.includes(sample: :taxon).where(sample: { taxons: { name: species } }, lab_identifier: labnr).count, json_response.size

    taxa = json_response.map { |entry| entry.dig("measurement", "species") }.uniq
    assert_equal 1, taxa.length
    assert_includes taxa, species

    labnrs = json_response.map { |entry| entry.dig("measurement", "labnr") }.uniq
    assert_equal 1, labnrs.length
    assert_includes labnrs, labnr
  end
end