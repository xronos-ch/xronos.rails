require "application_system_test_case"

class TaxonUsageSystemTest < ApplicationSystemTestCase
  test "taxon usage loads asynchronously via turbo frame" do
    id = 2877951

    # Stub GBIF API request
    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(
        status: 200,
        body: {
          canonicalName: "Quercus robur",
          rank: "SPECIES"
        }.to_json
      )

    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: id)

    visit taxon_path(taxon)

    # placeholder is visible initially
    assert_selector ".placeholder"

    # wait for Turbo frame to update
    assert_text "Quercus robur"
  end

  test "handles GBIF failure gracefully" do
    id = 2877951

    stub_request(:get, "https://api.gbif.org/v1/species/#{id}")
      .to_return(status: 500)

    taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: id)

    visit taxon_path(taxon)

    # should not crash
    assert_no_text "Quercus robur"
  end

end
