require "test_helper"

# Ensure Devise mappings are loaded before any sign_in call; the test
# environment does not eager-load routes by default.
Rails.application.routes.eager_load!

class TaxonsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @taxon = FactoryBot.create(:taxon, name: "Quercus robur", gbif_id: 1)
    @admin = FactoryBot.create(:user, :admin)
    sign_in @admin
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

  test "index excludes unknown taxons when matched_only param is present" do
    FactoryBot.create(:taxon, name: "Matched", gbif_id: 1)
    FactoryBot.create(:taxon, name: "Unmatched", gbif_id: nil)

    get taxons_path(format: :json, q: "match", matched_only: true)

    assert_response :success

    json = JSON.parse(response.body)
    names = json.map { |t| t["name"] }

    assert_includes names, "Matched"
    assert_not_includes names, "Unmatched"
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


  #
  # Duplicate rejection (issue #310)
  #

  test "create rejects an exact duplicate taxon with a validation error" do
    # @taxon (created in setup) is the older canonical. The create
    # is rejected by `validate :no_exact_duplicate, on: :create`; no
    # auto-merge happens on the create path.
    assert_equal 1, Taxon.count

    assert_no_difference "Taxon.count" do
      post taxons_path(format: :json),
           params: { taxon: { name: "Quercus robur", gbif_id: 1 } }
    end

    assert_response :unprocessable_entity
    assert_equal 1, Taxon.count
  end

  test "update merges a taxon into an existing duplicate and reassigns samples" do
    # @taxon is the older canonical; create a younger taxon with a sample.
    other = FactoryBot.create(:taxon, name: "Fagus sylvatica", gbif_id: 2)
    sample = FactoryBot.create(:sample, taxon: other)
    assert_equal 2, Taxon.count

    patch taxon_path(other), params: { taxon: { name: "Quercus robur", gbif_id: 1 } }

    assert_response :redirect
    assert_equal 1, Taxon.count
    assert_equal @taxon.id, Taxon.first.id
    assert_equal @taxon.id, sample.reload.taxon_id
  end

  test "create with no duplicate creates a new taxon" do
    assert_difference "Taxon.count", 1 do
      post taxons_path, params: { taxon: { name: "Pinus sylvestris", gbif_id: 3 } }
    end

    assert_response :redirect
    assert_equal 2, Taxon.count
  end

end
