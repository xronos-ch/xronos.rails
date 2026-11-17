require "test_helper"

class TaxonUsageTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear

    @id = 2877951
    @url = "https://api.gbif.org/v1/species/#{@id}"

    @response = {
      "canonicalName" => "Quercus robur",
      "scientificName" => "Quercus robur L.",
      "authorship" => "L.",
      "rank" => "SPECIES"
    }

    stub_request(:get, @url)
      .to_return(status: 200, body: @response.to_json)
  end

  #
  # basic GBIF call
  #
  test "fetches GBIF data via usage endpoint" do
    usage = TaxonUsage.new(id: @id)

    result = usage.gbif

    assert_equal "Quercus robur", result["canonicalName"]
    assert_requested :get, @url, times: 1
  end

  #
  # attribute accessors
  #
  test "returns canonical_name" do
    usage = TaxonUsage.new(id: @id)
    assert_equal "Quercus robur", usage.canonical_name
  end

  test "returns rank" do
    usage = TaxonUsage.new(id: @id)
    assert_equal "SPECIES", usage.rank
  end

  test "returns authorship" do
    usage = TaxonUsage.new(id: @id)
    assert_equal "L.", usage.authorship
  end

  #
  # missing values handled safely
  #
  test "returns nil when fields are missing" do
    stub_request(:get, @url)
      .to_return(status: 200, body: {}.to_json)

    usage = TaxonUsage.new(id: @id)

    assert_nil usage.canonical_name
    assert_nil usage.rank
    assert_nil usage.authorship
  end

  #
  # URLs
  #
  test "returns public GBIF URL" do
    usage = TaxonUsage.new(id: @id)

    assert_equal "https://www.gbif.org/species/#{@id}", usage.url
  end

  test "returns API URL" do
    usage = TaxonUsage.new(id: @id)

    assert_equal @url, usage.api_url
  end

  #
  # delegates exactly once per accessor set (via cache)
  #
  test "reuses cached GBIF response across attribute calls" do
    usage = TaxonUsage.new(id: @id)

    usage.canonical_name
    usage.rank
    usage.authorship

    # should only call once (assuming GBIF::Species caching works)
    assert_requested :get, @url, times: 1
  end

  #
  # error handling
  #
  test "returns nil when API request fails" do
    stub_request(:get, @url)
      .to_return(status: 500)

    usage = TaxonUsage.new(id: @id)

    assert_nil usage.canonical_name
    assert_nil usage.rank
    assert_nil usage.authorship
  end

  #
  # initialisation
  #
  test "initialises with id" do
    usage = TaxonUsage.new(id: @id)

    assert_equal @id, usage.id
  end
end
