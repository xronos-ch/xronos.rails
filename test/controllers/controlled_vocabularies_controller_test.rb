require "test_helper"

class ControlledVocabulariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vocabulary = create(:controlled_vocabulary, name: "part_of_organism")
    @other_vocabulary = create(:controlled_vocabulary, name: "preservation_state")

    @cob = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cob (maize)", ontology_name: "PO", ontology_id: "PO:0009006")
    @cranium = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cranium", ontology_name: "UBERON", ontology_id: "UBERON:0000029")
    @femur = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Femur", ontology_name: "UBERON", ontology_id: "UBERON:0000981")
    create(:controlled_vocabulary_term, vocabulary: @other_vocabulary, name: "Cob (maize)")
  end

  test "index returns the terms of the named vocabulary" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    names = json.map { |t| t["name"] }
    assert_includes names, "Cob (maize)"
    assert_includes names, "Cranium"
    assert_includes names, "Femur"
    assert_equal 3, json.length
  end

  test "index does not include terms from other vocabularies" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    # The other vocabulary also has a term named "Cob (maize)" — it must not
    # leak across the vocabulary boundary.
    assert_equal 3, json.length
  end

  test "index filters by q when present" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "cob")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal ["Cob (maize)"], json.map { |t| t["name"] }
  end

  test "index treats a blank q as no filter" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 3, json.length
  end

  test "index includes ontology_name, ontology_id, and ontology url" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Cranium")

    assert_response :success

    json = JSON.parse(response.body)
    term = json.first

    assert_equal "Cranium", term["name"]
    assert_equal "UBERON", term["ontology_name"]
    assert_equal "UBERON:0000029", term["ontology_id"]
    assert_equal "https://www.ebi.ac.uk/ols4/ontologies/uberon/terms?iri=http://purl.obolibrary.org/obo/UBERON:0000029",
      term["url"]
  end

  test "index returns 400 when the vocabulary param is missing" do
    get controlled_vocabularies_path(format: :json)

    assert_response :bad_request
  end

  test "index returns 400 when the vocabulary param is blank" do
    get controlled_vocabularies_path(format: :json, vocabulary: "")

    assert_response :bad_request
  end

  test "index returns 400 when more than one vocabulary is requested" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: ["part_of_organism", "preservation_state"])

    assert_response :bad_request
  end

  test "index returns 404 when the vocabulary does not exist" do
    get controlled_vocabularies_path(format: :json, vocabulary: "nonexistent")

    assert_response :not_found
  end

  test "index caps results at 20" do
    25.times do |i|
      create(:controlled_vocabulary_term, vocabulary: @vocabulary,
        name: "Term #{i.to_s.rjust(2, '0')}")
    end

    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 20, json.length
  end

  test "index is accessible to the public (no sign in)" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success
  end
end
