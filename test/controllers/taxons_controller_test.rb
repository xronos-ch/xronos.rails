require "test_helper"

class TaxonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: 1)
  end

  #
  # INDEX
  #

  test "index returns all taxons when no query" do
    FactoryBot.create(:taxon, name: "Fagus sylvatica")

    get taxons_path(format: :json)

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal Taxon.count, json.size
  end

  test "index performs local search when q present" do
    Taxon.create!(name: "Fagus sylvatica")

    get taxons_path(format: :json, q: "Fagus")

    assert_response :success

    json = JSON.parse(response.body)
    assert json.any? { |t| t["name"] == "Fagus sylvatica" }
  end

  test "index uses GBIF when search_gbif param present" do
    stub_request(:get, /api.gbif.org/)
      .to_return(
        status: 200,
        body: {
          "results" => [
            { "canonicalName" => "GBIF Taxon", "usageKey" => 999 }
          ]
        }.to_json
      )

    get taxons_path(format: :json, q: "GBIF", search_gbif: true)

    assert_response :success

    json = JSON.parse(response.body)
    assert json.any? { |t| t["name"] == "GBIF Taxon" }
  end

  test "index limits local results to 5" do
    10.times { |i| FactoryBot.create(:taxon, name: "Test #{i}") }

    get taxons_path(format: :json, q: "Test")

    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :<=, 5
  end

  test "index returns CSV" do
    get taxons_path(format: :csv)

    assert_response :success
    assert_includes response.headers["Content-Type"], "text/csv"
  end

  test "index rejects HTML" do
    get taxons_path

    assert_response :not_acceptable
  end

end
