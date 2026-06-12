require "test_helper"

class SyncTaxonWithGbifJobTest < ActiveJob::TestCase
  setup do
    Rails.cache.clear
  end

  #
  # CORE SUCCESS CASE
  #
  test "sets gbif_id and canonical name for exact match" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: nil)

    stub_match_by_name("Quercus robur", {
      usageKey: 2877951,
      canonicalName: "Quercus robur",
      matchType: "EXACT"
    })

    perform_now(taxon)

    taxon.reload

    assert_equal 2877951, taxon.gbif_id
    assert_equal "Quercus robur", taxon.name
  end

  #
  # CANONICAL NAME ENFORCED
  #
  test "updates name to canonical GBIF name" do
    taxon = FactoryBot.create(
      :taxon,
      name: "Quercus robbur",  # typo
      gbif_id: nil
    )

    stub_match_by_name("Quercus robbur", {
      usageKey: 2877951,
      canonicalName: "Quercus robur",
      matchType: "EXACT"
    })

    perform_now(taxon)

    taxon.reload

    assert_equal 2877951, taxon.gbif_id
    assert_equal "Quercus robur", taxon.name
  end

  #
  # NO EXACT MATCH → NO CHANGES
  #
  test "does nothing when match is not EXACT" do
    taxon = FactoryBot.create(:taxon, name: "Unknown taxon", gbif_id: nil)

    stub_match_by_name("Unknown taxon", {
      matchType: "FUZZY"
    })

    perform_now(taxon)

    taxon.reload

    assert_nil taxon.gbif_id
    assert_equal "Unknown taxon", taxon.name
  end

  #
  # GBIF ID ALREADY PRESENT → SKIP MATCH STEP
  #
  test "does not rematch when gbif_id already set but enforces canonical name" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robbur", gbif_id: 2877951)

    stub_match_by_usage_key(2877951, {
      usageKey: 2877951,
      canonicalName: "Quercus robur"
    })

    perform_now(taxon)

    taxon.reload

    assert_equal 2877951, taxon.gbif_id
    assert_equal "Quercus robur", taxon.name
  end

  #
  # CACHING: NO DUPLICATE REQUESTS
  #
  test "uses cached responses across multiple runs" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: nil)

    stub_match_by_name("Quercus robur", {
      usageKey: 2877951,
      canonicalName: "Quercus robur",
      matchType: "EXACT"
    })

    stub_match_by_usage_key(2877951, {
      usageKey: 2877951,
      canonicalName: "Quercus robur"
    })

    perform_now(taxon)
    perform_now(taxon)

    # One call per distinct query
    assert_requested :get, gbif_match_url,
      query: hash_including(
        "scientificName" => "Quercus robur",
        "strict" => "true"
      ),
      times: 1

    assert_requested :get, gbif_match_url,
      query: hash_including("usageKey" => "2877951"),
      times: 1
  end

  test "reuses initial match result and does not call usageKey lookup for EXACT match" do
    taxon = FactoryBot.create(
      :taxon,
      name: "Quercus robbur",
      gbif_id: nil
    )

    # Stub ONLY the initial match
    stub_match_by_name("Quercus robbur", {
      usageKey: 2877951,
      canonicalName: "Quercus robur",
      matchType: "EXACT"
    })

    # No stub for usageKey on purpose

    SyncTaxonWithGbifJob.perform_now(taxon.id)

    taxon.reload

    # Behaviour is still correct
    assert_equal 2877951, taxon.gbif_id
    assert_equal "Quercus robur", taxon.name

    # Initial call happened
    assert_requested :get, gbif_match_url,
      query: hash_including(
        "scientificName" => "Quercus robbur",
        "strict" => "true"
      ),
      times: 1

    # But no fallback call was made
    assert_not_requested :get, gbif_match_url,
      query: hash_including("usageKey" => "2877951")
  end

  #
  # TIMEOUT HANDLING
  #
  test "does nothing on timeout" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: nil)

    stub_request(:get, gbif_match_url)
      .with(query: hash_including("scientificName" => "Quercus robur"))
      .to_timeout

    perform_now(taxon)

    taxon.reload

    assert_nil taxon.gbif_id
    assert_equal "Quercus robur", taxon.name
  end

  #
  # ID LOOKUP FAILS → NO CRASH
  #
  test "handles missing canonical name gracefully" do
    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: nil)

    stub_match_by_name("Quercus robur", {
      usageKey: 2877951,
      matchType: "EXACT"
    })

    stub_match_by_usage_key(2877951, {
      usageKey: 2877951,
      canonicalName: nil
    })

    perform_now(taxon)

    taxon.reload

    # gbif_id still set
    assert_equal 2877951, taxon.gbif_id
  end

  private

  #
  # TEST HELPERS
  #

  def perform_now(taxon)
    SyncTaxonWithGbifJob.perform_now(taxon.id)
  end

  def gbif_match_url
    "https://api.gbif.org/v2/species/match"
  end

  def stub_match_by_name(name, body)
    stub_request(:get, gbif_match_url)
      .with(query: hash_including(
        "scientificName" => name,
        "strict" => "true"
      ))
      .to_return(status: 200, body: body.to_json)
  end

  def stub_match_by_usage_key(key, body)
    stub_request(:get, gbif_match_url)
      .with(query: hash_including("usageKey" => key.to_s))
      .to_return(status: 200, body: body.to_json)
  end
end

