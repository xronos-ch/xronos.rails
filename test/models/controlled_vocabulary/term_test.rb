# == Schema Information
#
# Table name: controlled_vocabulary_terms
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  description              :text
#  name                     :string           not null
#  ontology_name            :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  controlled_vocabulary_id :bigint           not null
#  ontology_id              :string
#
# Indexes
#
#  index_cv_terms_on_ontology                      (ontology_name,ontology_id) UNIQUE WHERE ((ontology_name IS NOT NULL) AND (ontology_id IS NOT NULL))
#  index_cv_terms_on_vocabulary_ontology_and_name  (controlled_vocabulary_id,ontology_name,name) UNIQUE
#
require "test_helper"

class ControlledVocabulary::TermTest < ActiveSupport::TestCase
  test "factory creates a valid term" do
    assert create(:controlled_vocabulary_term).valid?
  end

  test "requires a name" do
    term = build(:controlled_vocabulary_term, name: nil)

    assert_not term.valid?
    assert_includes term.errors[:name], "can't be blank"
  end

  test "requires a unique name within its vocabulary" do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")
    duplicate = build(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows the same name in a different vocabulary" do
    one = create(:controlled_vocabulary)
    other = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: one, name: "Cob")

    assert build(:controlled_vocabulary_term, vocabulary: other, name: "Cob").valid?
  end

  test "requires ontology_id when ontology_name is set" do
    term = build(:controlled_vocabulary_term, ontology_name: "UBERON", ontology_id: nil)

    assert_not term.valid?
    assert_includes term.errors[:ontology_id], "can't be blank"
  end

  test "requires ontology_name when ontology_id is set" do
    term = build(:controlled_vocabulary_term, ontology_name: nil, ontology_id: "UBERON:0000029")

    assert_not term.valid?
    assert_includes term.errors[:ontology_name], "can't be blank"
  end

  test "requires unique (ontology_name, ontology_id) pair" do
    create(:controlled_vocabulary_term, ontology_name: "UBERON", ontology_id: "UBERON:0000029")
    duplicate = build(:controlled_vocabulary_term,
      ontology_name: "UBERON", ontology_id: "UBERON:0000029")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:ontology_name], "has already been taken"
  end

  test "allows the same ontology_id under a different ontology" do
    create(:controlled_vocabulary_term, ontology_name: "UBERON", ontology_id: "X")
    other = build(:controlled_vocabulary_term, ontology_name: "PO", ontology_id: "X")

    assert other.valid?
  end

  test "ontology_url builds the UBERON URL" do
    term = build(:controlled_vocabulary_term,
      ontology_name: "UBERON", ontology_id: "UBERON:0000029")

    assert_equal "https://www.ebi.ac.uk/ols4/ontologies/uberon/terms?iri=http://purl.obolibrary.org/obo/UBERON:0000029",
                 term.ontology_url
  end

  test "ontology_url builds the PO URL" do
    term = build(:controlled_vocabulary_term,
      ontology_name: "PO", ontology_id: "PO:0009006")

    assert_equal "https://www.ebi.ac.uk/ols4/ontologies/po/terms?iri=http://purl.obolibrary.org/obo/PO:0009006",
                 term.ontology_url
  end

  test "ontology_url returns nil for an unknown ontology" do
    term = build(:controlled_vocabulary_term, ontology_name: "DOES_NOT_EXIST", ontology_id: "X:Y")

    assert_nil term.ontology_url
  end

  test "ontology_url returns nil when only one of ontology_name or ontology_id is set" do
    assert_nil build(:controlled_vocabulary_term, ontology_name: "UBERON", ontology_id: nil).ontology_url
    assert_nil build(:controlled_vocabulary_term, ontology_name: nil, ontology_id: "UBERON:0000029").ontology_url
  end

  test "destroying a term cascades to its variants" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term)

    term.destroy!

    assert_equal 0, ControlledVocabulary::Variant.where(controlled_vocabulary_term_id: term.id).count
  end

  test "search returns terms whose name matches the query" do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob (maize)")
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cranium")
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Femur")

    results = vocabulary.terms.search("cob").to_a

    assert_equal ["Cob (maize)"], results.map(&:name)
  end

  test "search is prefix-matched" do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob (maize)")
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cranium")

    results = vocabulary.terms.search("cra").to_a

    assert_equal ["Cranium"], results.map(&:name)
  end

  test "description_excerpt returns nil for a missing description" do
    term = build(:controlled_vocabulary_term, description: nil)
    assert_nil term.description_excerpt

    blank = build(:controlled_vocabulary_term, description: "")
    assert_nil blank.description_excerpt
  end

  test "description_excerpt returns the original when shorter than max" do
    term = build(:controlled_vocabulary_term, description: "Short.")

    assert_equal "Short.", term.description_excerpt
    assert_equal "Short.", term.description_excerpt(max: 50)
  end

  test "description_excerpt truncates with an ellipsis when longer than max" do
    text = "a" * 250
    term = build(:controlled_vocabulary_term, description: text)

    excerpt = term.description_excerpt(max: 200)

    assert_equal 201, excerpt.length          # 200 chars + "…"
    assert_equal "a" * 200 + "…", excerpt
  end

  test "description_excerpt honours a custom max" do
    term = build(:controlled_vocabulary_term, description: "abcdefghij")

    assert_equal "abcde…", term.description_excerpt(max: 5)
  end
end
