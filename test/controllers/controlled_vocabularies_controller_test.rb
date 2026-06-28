require "test_helper"

class ControlledVocabulariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vocabulary = create(:controlled_vocabulary, name: "part_of_organism")
    @other_vocabulary = create(:controlled_vocabulary, name: "preservation_state")

    @cob = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cob (maize)", ontology_name: "PO", ontology_id: "PO:0009006")
    @cranium = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cranium", ontology_name: "UBERON", ontology_id: "UBERON:0000029",
      description: "Skull, excluding the mandible.")
    @femur = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Femur", ontology_name: "UBERON", ontology_id: "UBERON:0000981")
    create(:controlled_vocabulary_term, vocabulary: @other_vocabulary, name: "Cob (maize)")

    @maize_variant = create(:controlled_vocabulary_variant,
      term: @cob, value: "maize cob")
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
    assert json.all? { |t| t["match"] == "term" }
  end

  test "index does not include terms from other vocabularies" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    # The other vocabulary also has a term named "Cob (maize)" — it must not
    # leak across the vocabulary boundary.
    assert_equal 3, json.length
  end

  test "index filters by q via term-name prefix match" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "cra")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal ["Cranium"], json.map { |t| t["name"] }
    assert_equal "term", json.first["match"]
    assert_nil json.first["matched_variant"]
  end

  test "index resolves a known variant and returns the canonical term first" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "maize cob")

    assert_response :success

    json = JSON.parse(response.body)
    first = json.first

    assert_equal "Cob (maize)", first["name"]
    assert_equal "variant", first["match"]
    assert_equal "maize cob", first["matched_variant"]
  end

  test "index resolves a case-mismatched variant" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "MAIZE COB")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Cob (maize)", json.first["name"]
    assert_equal "variant", json.first["match"]
    assert_equal "MAIZE COB", json.first["matched_variant"]
  end

  test "index variant match is not duplicated in the trigram results" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "maize cob")

    assert_response :success

    json = JSON.parse(response.body)
    cob_entries = json.select { |t| t["name"] == "Cob (maize)" }

    assert_equal 1, cob_entries.length
  end

  test "index does not leak variants from a different vocabulary" do
    other_cob = @other_vocabulary.terms.first
    create(:controlled_vocabulary_variant, term: other_cob, value: "charred wood")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "charred wood")

    assert_response :success

    json = JSON.parse(response.body)
    assert_empty json
  end

  test "index resolves a variant of a term with no ontology" do
    no_ontology = create(:controlled_vocabulary_term,
      vocabulary: @vocabulary, name: "Local term")
    create(:controlled_vocabulary_variant, term: no_ontology, value: "local term alias")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "local term alias")

    assert_response :success

    json = JSON.parse(response.body)
    first = json.first

    assert_equal "Local term", first["name"]
    assert_equal "variant", first["match"]
    assert_nil first["ontology_name"]
    assert_nil first["ontology_id"]
    assert_nil first["url"]
  end

  test "index returns the description field" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Cranium")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "Skull, excluding the mandible.", json.first["description"]
  end

  test "index truncates a long description with an ellipsis" do
    long = "a" * 250
    create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Long desc", description: long)

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Long")

    assert_response :success

    json = JSON.parse(response.body)
    excerpt = json.first["description"]

    assert_equal 201, excerpt.length          # 200 chars + "…"
    assert excerpt.end_with?("…")
  end

  test "index returns nil description for terms without one" do
    create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Undescribed", description: nil)

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Undescribed")

    assert_response :success

    json = JSON.parse(response.body)
    assert_nil json.first["description"]
  end

  test "index caps results at 20 with variant + trigram combined" do
    24.times do |i|
      create(:controlled_vocabulary_term, vocabulary: @vocabulary,
        name: "Extra #{i.to_s.rjust(2, '0')}")
    end

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "extra")

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 20, json.length
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

  test "index is accessible to the public (no sign in)" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success
  end
end
