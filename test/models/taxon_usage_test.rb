require "test_helper"

class TaxonUsageTest < ActiveSupport::TestCase

  test "fetches usage data from GBIF species endpoint" do
    stub_request(:get, "https://api.gbif.org/v1/species/2877951")
      .to_return(status: 200, body: { canonicalName: "Quercus robur" }.to_json)

    usage = TaxonUsage.new(id: 2877951)

    assert_equal "Quercus robur", usage.canonical_name
  end

end
