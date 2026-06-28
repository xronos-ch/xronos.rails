require "application_system_test_case"

class TaxonUsageSystemTest < ApplicationSystemTestCase
  setup do
    WebMock.disable_net_connect!(allow_localhost: true)
    Rails.cache.clear
  end

  #
  # Direct endpoint: taxon_usage show
  #
  test "taxon usage show renders canonical name" do
    id = 2877951

    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(
        status: 200,
        body: {
          canonicalName: "Quercus robur",
          rank: "SPECIES"
        }.to_json
      )

    visit taxon_usage_path(id)

    assert_text "Quercus robur"
  end

  test "taxon usage show handles GBIF failure gracefully" do
    id = 2877951

    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(status: 500)

    visit taxon_usage_path(id)

    assert_text "GBIF data unavailable"
  end

  #
  # Full integration: async loading via Turbo frame on c14 show
  #
  test "taxon usage loads asynchronously on c14 show page" do
    id = 2877951

    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(
        status: 200,
        body: {
          canonicalName: "Quercus robur",
          rank: "SPECIES"
        }.to_json
      )

    taxon  = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: id)
    sample = FactoryBot.create(:sample, taxon: taxon)
    c14    = FactoryBot.create(:c14, sample: sample)

    visit c14_path(c14)

    # Turbo frame is present initially
    assert_selector "##{dom_id(taxon.usage)}"

    # Wait for async content
    within "##{dom_id(taxon.usage)}" do
      assert_text "Quercus robur"
    end
  end

  test "taxon usage shows fallback when GBIF request fails on c14 page" do
    id = 2877951

    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(status: 500)

    taxon  = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: id)
    sample = FactoryBot.create(:sample, taxon: taxon)
    c14    = FactoryBot.create(:c14, sample: sample)

    visit c14_path(c14)

    within "##{dom_id(taxon.usage)}" do
      assert_text "GBIF data unavailable"
    end
  end
end

