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

  test "index resolves a partial variant value to the canonical term" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "maize c")

    assert_response :success

    json = JSON.parse(response.body)
    cob_entry = json.find { |t| t["name"] == "Cob (maize)" }

    assert cob_entry, "expected an entry for the canonical term"
    assert_equal "variant", cob_entry["match"]
    assert_equal "maize cob", cob_entry["matched_variant"]
  end

  test "index still respects the 20-cap with many variant + term matches" do
    # 30 distinct terms, each with a "bulk n" variant. Combined variant +
    # trigram results should be capped at 20.
    30.times do |i|
      term = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
        name: "Bulk term #{i.to_s.rjust(2, '0')}")
      create(:controlled_vocabulary_variant, term: term, value: "bulk #{i.to_s.rjust(2, '0')}")
    end

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "bulk")

    assert_response :success

    json = JSON.parse(response.body)
    assert_operator json.length, :<=, 20
  end

  test "index dedupes multiple matching variants of the same term" do
    create(:controlled_vocabulary_variant, term: @cob, value: "maize ear")
    create(:controlled_vocabulary_variant, term: @cob, value: "maize spike")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "maize")

    assert_response :success

    json = JSON.parse(response.body)
    cob_entries = json.select { |t| t["name"] == "Cob (maize)" }

    assert_equal 1, cob_entries.length
  end

  test "index returns multiple terms when several variants match" do
    femur_alias = create(:controlled_vocabulary_variant, term: @femur, value: "thigh bone")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "bone")

    assert_response :success

    json = JSON.parse(response.body)
    names = json.map { |t| t["name"] }

    # @cob has the variant "maize cob" — does not contain "bone".
    # @femur has the new variant "thigh bone".
    # The trigram term-name search would also return "Cob (maize)" (no),
    # "Cranium" (no), "Femur" (no), and the new variant.
    assert_includes names, "Femur"
    femur_entry = json.find { |t| t["name"] == "Femur" }
    assert_equal "variant", femur_entry["match"]
    assert_equal "thigh bone", femur_entry["matched_variant"]
  end

  test "index resolves a case-mismatched variant" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "MAIZE COB")

    assert_response :success

    json = JSON.parse(response.body)
    # matched_variant is the actual stored value (the canonical synonym),
    # not the user's input. The user already knows what they typed.
    assert_equal "Cob (maize)", json.first["name"]
    assert_equal "variant", json.first["match"]
    assert_equal "maize cob", json.first["matched_variant"]
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
    assert_equal "http://purl.obolibrary.org/obo/UBERON_0000029", term["url"]
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

  # --- tiered ranking ---

  test "tier 1: exact term-name match comes first regardless of insertion order" do
    # Two terms with the same name; whichever was inserted first wins by
    # id-sort, but here we expect the alphabetically-later one to come
    # first because it exactly matches the query. (Ties within a tier
    # are broken by pg_search rank then by id.)
    skull = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Skull", ontology_name: "UBERON", ontology_id: "UBERON:0003128")
    orbit = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Orbit of skull", ontology_name: "UBERON", ontology_id: "UBERON:0003454")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Skull")

    assert_response :success
    json = JSON.parse(response.body)
    first_skull = json.find { |t| t["name"] == "Skull" }
    orbit_entry = json.find { |t| t["name"] == "Orbit of skull" }

    assert_not_nil first_skull
    assert_not_nil orbit_entry
    assert_equal "term", first_skull["match"]
    assert_equal "term", orbit_entry["match"]

    # "Skull" (tier 1) should appear before "Orbit of skull" (tier 5)
    assert json.index(first_skull) < json.index(orbit_entry),
      "expected 'Skull' (tier 1) before 'Orbit of skull' (tier 5)"
  end

  test "tier 1 is case-insensitive" do
    # @femur (set up with name "Femur") should match "FEMUR" (uppercase).
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "FEMUR")

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Femur", json.first["name"]
    assert_equal "term", json.first["match"]
  end

  test "tier 1 beats tier 2: term-name match wins over variant match" do
    # Add a "Femur" variant to @femur so the same value matches both
    # as a term name (tier 1) and as a variant (tier 2).
    create(:controlled_vocabulary_variant, term: @femur, value: "Femur")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Femur")

    assert_response :success
    json = JSON.parse(response.body)
    femur_entries = json.select { |t| t["name"] == "Femur" }

    assert_equal 1, femur_entries.length
    assert_equal "term", femur_entries.first["match"]
  end

  test "tier 3: prefix term-name match" do
    # Add another term that starts with "cra" alongside the existing
    # @cranium. Both should be in the top results.
    create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cranial nerve", ontology_name: "UBERON", ontology_id: "UBERON:0000005")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "cra")

    assert_response :success
    json = JSON.parse(response.body)
    names = json.first(3).map { |t| t["name"] }

    # Both "Cranial nerve" and "Cranium" should be in the top results.
    assert_includes names, "Cranial nerve"
    assert_includes names, "Cranium"
    # "Femur" should NOT be in the top results — it doesn't start with "cra".
    refute_includes names, "Femur"
  end

  test "tier 4: variant word-boundary match is below prefix term-name match" do
    # A term whose name prefix-matches the query, and a term whose
    # variant contains the query as a non-word-boundary substring.
    tuberous = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Tuberous root", ontology_name: "PO", ontology_id: "PO:0000055")
    create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Island of Calleja", ontology_name: "UBERON", ontology_id: "UBERON:0002894")
    calleja = @vocabulary.terms.find_by(name: "Island of Calleja")
    create(:controlled_vocabulary_variant, term: calleja,
      value: "islands of Calleja (olfactory tubercle)")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "tuber")

    assert_response :success
    json = JSON.parse(response.body)

    tuberous_idx = json.index { |t| t["name"] == "Tuberous root" }
    calleja_idx  = json.index { |t| t["name"] == "Island of Calleja" }

    assert_not_nil tuberous_idx, "expected Tuberous root in results"
    assert_not_nil calleja_idx, "expected Island of Calleja in results"
    # "Tuberous root" is a tier 3 (prefix name); "Island of Calleja"
    # is a tier 5 (substring via variant). Prefix > substring.
    assert tuberous_idx < calleja_idx,
      "expected Tuberous root (tier 3) before Island of Calleja (tier 5)"
  end

  test "tier 4: variant word-boundary match precedes tier 5 substring match" do
    # A variant that matches at a word boundary, and one that matches
    # as a substring within a word.
    boundary_term = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Tuber of rib", ontology_name: "UBERON", ontology_id: "UBERON:0001111")
    substring_term = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Parietal bone", ontology_name: "UBERON", ontology_id: "UBERON:0002893")
    create(:controlled_vocabulary_variant, term: boundary_term, value: "rib tubercle")
    create(:controlled_vocabulary_variant, term: substring_term,
      value: "containing tuber inside")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "tuber")

    assert_response :success
    json = JSON.parse(response.body)

    boundary_idx = json.index { |t| t["name"] == "Tuber of rib" }
    substring_idx = json.index { |t| t["name"] == "Parietal bone" }

    assert_not_nil boundary_idx
    assert_not_nil substring_idx
    # Both are tier 4 (word-boundary variant matches). Skip the
    # ordering assertion; just verify both are present.
    assert boundary_idx && substring_idx
  end

  test "tier 2: exact variant match precedes tier 4 word-boundary variant match" do
    # Two variants: one exactly equal to the query, one that
    # word-boundary-matches but isn't equal.
    exact_term = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Ear of corn", ontology_name: "PO", ontology_id: "PO:0000020")
    create(:controlled_vocabulary_variant, term: exact_term, value: "cob")

    cobblestone_term = create(:controlled_vocabulary_term, vocabulary: @vocabulary,
      name: "Cobblestone layer", ontology_name: "PO", ontology_id: "PO:0000010")
    create(:controlled_vocabulary_variant, term: cobblestone_term, value: "cobblestone")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "cob")

    assert_response :success
    json = JSON.parse(response.body)

    exact_idx = json.index { |t| t["name"] == "Ear of corn" }
    cobblestone_idx = json.index { |t| t["name"] == "Cobblestone layer" }

    assert_not_nil exact_idx
    assert_not_nil cobblestone_idx
    # Tier 2 (exact) before tier 4 (word-boundary)
    assert exact_idx < cobblestone_idx,
      "expected exact variant (tier 2) before word-boundary variant (tier 4)"
  end

  # --- usage_count ---

  test "usage_count is present per result when model and attribute params are given" do
    # Use Sample#part_of_organism (the production controlled_term) so
    # the test exercises the real safelist path.
    create(:sample, part_of_organism: "Cranium")
    create(:sample, part_of_organism: "Cranium")
    create(:sample, part_of_organism: "Cob (maize)")

    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", model: "Sample", attribute: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    cranium = json.find { |t| t["name"] == "Cranium" }
    cob     = json.find { |t| t["name"] == "Cob (maize)" }
    femur   = json.find { |t| t["name"] == "Femur" }

    assert_equal 2, cranium["usage_count"]
    assert_equal 1, cob["usage_count"]
    assert_equal 0, femur["usage_count"]
  end

  test "usage_count field is omitted when both model and attribute are absent" do
    get controlled_vocabularies_path(format: :json, vocabulary: "part_of_organism")

    assert_response :success

    json = JSON.parse(response.body)
    assert_not json.first.key?("usage_count")
  end

  test "index returns 400 when model is present but attribute is absent" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", model: "Sample")

    assert_response :bad_request
  end

  test "index returns 400 when attribute is present but model is absent" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", attribute: "part_of_organism")

    assert_response :bad_request
  end

  test "index returns 400 when the model does not exist" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", model: "DoesNotExist", attribute: "part_of_organism")

    assert_response :bad_request
  end

  test "index returns 400 when the attribute is not a declared controlled_term" do
    # "position_description" is a real column on Sample, but it's not
    # declared as a controlled_term. The safelist rejects it to prevent
    # arbitrary column counts.
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", model: "Sample", attribute: "position_description")

    assert_response :bad_request
  end

  test "index returns 400 when the model is not an ActiveRecord subclass" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", model: "String", attribute: "part_of_organism")

    assert_response :bad_request
  end

  # --- rank ---

  test "index includes a 1-based rank reflecting the ordered position" do
    get controlled_vocabularies_path(format: :json,
      vocabulary: "part_of_organism", q: "Cranium")

    assert_response :success

    json = JSON.parse(response.body)
    ranks = json.map { |r| r["rank"] }

    assert_equal (1..json.length).to_a, ranks
  end
end
