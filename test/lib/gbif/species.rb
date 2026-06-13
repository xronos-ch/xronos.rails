require "test_helper"

class GBIF::SpeciesTest < ActiveSupport::TestCase

  test ".usage fetches species data by id" do
    url = "https://api.gbif.org/v1/species/2877951"

    stub_request(:get, url)
      .to_return(
        status: 200,
        body: {
          canonicalName: "Quercus robur",
          scientificName: "Quercus robur L.",
          rank: "SPECIES"
        }.to_json
      )

    result = GBIF::Species.usage(2877951)

    assert_instance_of Hash, result
    assert_equal "Quercus robur", result["canonicalName"]
    assert_equal "SPECIES", result["rank"]
  end

  test ".usage caches responses" do
    url = "https://api.gbif.org/v1/species/2877951"

    stub_request(:get, url)
      .to_return(
        status: 200,
        body: { canonicalName: "Quercus robur" }.to_json
      )

    Rails.cache.clear

    result1 = GBIF::Species.usage(2877951)
    result2 = GBIF::Species.usage(2877951)

    assert_equal result1, result2

    # ✅ only one HTTP call
    assert_requested :get, url, times: 1
  end

  test ".usage returns nil on error" do
    url = "https://api.gbif.org/v1/species/999999"

    stub_request(:get, url)
      .to_return(status: 500, body: "error")

    result = GBIF::Species.usage(999999)

    assert_nil result
  end

  test ".usage returns nil on timeout" do
    url = "https://api.gbif.org/v1/species/2877951"

    stub_request(:get, url).to_timeout

    result = GBIF::Species.usage(2877951)

    assert_nil result
  end

  test ".match returns parsed JSON for successful request" do
    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    body = {
      usageKey: 2877951,
      canonicalName: "Quercus robur",
      matchType: "EXACT"
    }.to_json

    stub_request(:get, url)
      .to_return(status: 200, body: body)

    result = GBIF::Species.match(scientificName: "Quercus robur")

    assert_instance_of Hash, result
    assert_equal 2877951, result["usageKey"]
    assert_equal "EXACT", result["matchType"]
  end

  test ".match encodes multiple query parameters" do
    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur&strict=true"

    stub_request(:get, url)
      .to_return(status: 200, body: {}.to_json)

    GBIF::Species.match(
      scientificName: "Quercus robur",
      strict: true
    )

    assert_requested :get, url, times: 1
  end

  test ".match ignores nil parameters" do
    Rails.cache.clear

    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    stub_request(:get, url)
      .to_return(status: 200, body: {}.to_json)

    GBIF::Species.match(
      scientificName: "Quercus robur",
      strict: nil
    )

    assert_requested :get, url, times: 1
  end

  test ".match returns nil on non-success response" do
    Rails.cache.clear

    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    stub_request(:get, url)
      .to_return(status: 500, body: "error")

    result = GBIF::Species.match(scientificName: "Quercus robur")

    assert_nil result
  end

  test ".match returns nil on timeout" do
    Rails.cache.clear

    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    stub_request(:get, url).to_timeout

    result = GBIF::Species.match(scientificName: "Quercus robur")

    assert_nil result
  end

  test ".match supports usageKey lookup" do
    url = "https://api.gbif.org/v2/species/match?usageKey=2877951"

    stub_request(:get, url)
      .to_return(status: 200, body: { usageKey: 2877951 }.to_json)

    result = GBIF::Species.match(usageKey: 2877951)

    assert_equal 2877951, result["usageKey"]
  end

  test ".match caches identical requests" do
    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    body = {
      usageKey: 2877951,
      matchType: "EXACT"
    }.to_json

    stub_request(:get, url)
      .to_return(status: 200, body: body)

    Rails.cache.clear

    # First call → hits API
    result1 = GBIF::Species.match(scientificName: "Quercus robur")

    # Second call → should hit cache
    result2 = GBIF::Species.match(scientificName: "Quercus robur")

    assert_equal result1, result2

    assert_requested :get, url, times: 1
  end

  test ".match caches different params separately" do
    url1 = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"
    url2 = "https://api.gbif.org/v2/species/match?scientificName=Fagus+sylvatica"

    stub_request(:get, url1)
      .to_return(status: 200, body: { usageKey: 1 }.to_json)

    stub_request(:get, url2)
      .to_return(status: 200, body: { usageKey: 2 }.to_json)

    Rails.cache.clear

    GBIF::Species.match(scientificName: "Quercus robur")
    GBIF::Species.match(scientificName: "Fagus sylvatica")

    assert_requested :get, url1, times: 1
    assert_requested :get, url2, times: 1
  end

  test ".match ignores nil params in cache key" do
    url = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"

    stub_request(:get, url)
      .to_return(status: 200, body: { usageKey: 1 }.to_json)

    Rails.cache.clear

    GBIF::Species.match(scientificName: "Quercus robur", strict: nil)
    GBIF::Species.match(scientificName: "Quercus robur")

    assert_requested :get, url, times: 1
  end

  test "different endpoints do not share cache" do
    url1 = "https://api.gbif.org/v2/species/match?scientificName=Quercus+robur"
    url2 = "https://api.gbif.org/v1/species/123"

    stub_request(:get, url1)
      .to_return(status: 200, body: { usageKey: 1 }.to_json)

    stub_request(:get, url2)
      .to_return(status: 200, body: { usageKey: 123 }.to_json)

    Rails.cache.clear

    GBIF::Species.match(scientificName: "Quercus robur")
    GBIF::Species.get("v1/species/123")

    assert_requested :get, url1, times: 1
    assert_requested :get, url2, times: 1
  end

  test ".match caches nil responses" do
    url = "https://api.gbif.org/v2/species/match?scientificName=Unknown"

    stub_request(:get, url)
      .to_return(status: 500)

    Rails.cache.clear

    result1 = GBIF::Species.match(scientificName: "Unknown")
    result2 = GBIF::Species.match(scientificName: "Unknown")

    assert_nil result1
    assert_nil result2

    assert_requested :get, url, times: 1
  end

  test ".search calls GBIF species search endpoint" do
    stub_request(:get, "https://api.gbif.org/v1/species/search?q=Quercus&limit=10")
      .to_return(status: 200, body: { "results" => [] }.to_json)

    GBIF::Species.search(query: "Quercus")

    assert_requested :get, "https://api.gbif.org/v1/species/search?q=Quercus&limit=10"
  end

end
