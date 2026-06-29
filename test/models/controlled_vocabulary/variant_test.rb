# == Schema Information
#
# Table name: controlled_vocabulary_variants
# Database name: primary
#
#  id                            :bigint           not null, primary key
#  normalized                    :string           not null
#  value                         :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  controlled_vocabulary_term_id :bigint           not null
#
# Indexes
#
#  index_cv_variants_on_term_and_normalized  (controlled_vocabulary_term_id,normalized) UNIQUE
#  index_cv_variants_on_term_and_value       (controlled_vocabulary_term_id,value) UNIQUE
#
require "test_helper"

class ControlledVocabulary::VariantTest < ActiveSupport::TestCase
  test "factory creates a valid variant" do
    assert create(:controlled_vocabulary_variant).valid?
  end

  test "computes normalized from value before validation" do
    variant = build(:controlled_vocabulary_variant, value: "  Maize Cob  ")

    assert variant.valid?
    assert_equal "maize cob", variant.normalized
  end

  test "normalizes internal whitespace runs to a single space" do
    variant = build(:controlled_vocabulary_variant, value: "maize  cob")

    assert variant.valid?
    assert_equal "maize cob", variant.normalized
  end

  test "normalizes tabs and newlines as whitespace" do
    variant = build(:controlled_vocabulary_variant, value: "maize\tcob")

    assert variant.valid?
    assert_equal "maize cob", variant.normalized
  end

  test "preserves hyphens and parens" do
    hyphen = build(:controlled_vocabulary_variant, value: "T-cell")
    parens = build(:controlled_vocabulary_variant, value: "bone (cranium)")

    assert hyphen.valid?
    assert parens.valid?
    assert_equal "t-cell",          hyphen.normalized
    assert_equal "bone (cranium)",  parens.normalized
  end

  test "normalize_for_matching is symmetric with the callback" do
    # Regression guard: if these two ever drift, matches silently break.
    assert_equal "maize  cob".to_s.downcase.squish,
                 ControlledVocabulary::Variant.normalize_for_matching("maize  cob")
  end

  test "normalize_for_matching handles nil" do
    assert_equal "", ControlledVocabulary::Variant.normalize_for_matching(nil)
  end

  test "rejects a second variant whose value normalizes to an existing one (whitespace)" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")
    duplicate = build(:controlled_vocabulary_variant, term: term, value: "  maize  cob  ")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized], "has already been taken"
  end

  test "requires a value" do
    variant = build(:controlled_vocabulary_variant, value: nil)

    assert_not variant.valid?
    assert_includes variant.errors[:value], "can't be blank"
  end

  test "requires a unique value within the term" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")
    duplicate = build(:controlled_vocabulary_variant, term: term, value: "maize cob")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:value], "has already been taken"
  end

  test "allows the same value on a different term" do
    one = create(:controlled_vocabulary_term)
    other = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: one, value: "maize cob")

    assert build(:controlled_vocabulary_variant, term: other, value: "maize cob").valid?
  end

  test "rejects a second variant whose value normalizes to an existing one" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")
    duplicate = build(:controlled_vocabulary_variant, term: term, value: "  MAIZE COB  ")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:normalized], "has already been taken"
  end

  # --- search scope ---

  test "search returns variants whose normalized value matches exactly" do
    term = create(:controlled_vocabulary_term)
    variant = create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    results = ControlledVocabulary::Variant.search("maize cob").to_a

    assert_includes results, variant
  end

  test "search is prefix-matched" do
    term = create(:controlled_vocabulary_term)
    variant = create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    results = ControlledVocabulary::Variant.search("maize c").to_a

    assert_includes results, variant
  end

  test "search is case-insensitive via normalization" do
    term = create(:controlled_vocabulary_term)
    variant = create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    results = ControlledVocabulary::Variant.search("MAIZE COB").to_a

    assert_includes results, variant
  end

  test "search uses prefix matching on each token of the input" do
    # tsearch with prefix:true tokenises "ma" as ["ma"] and matches any
    # variant containing a word starting with "ma". The minimum word length
    # is 1, not the trigram minimum of 3. The 20-cap at the controller
    # level bounds the result count.
    term = create(:controlled_vocabulary_term)
    variant = create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    results = ControlledVocabulary::Variant.search("ma").to_a

    assert_includes results, variant
  end

  test "search returns nothing for an empty or blank input" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    assert_empty ControlledVocabulary::Variant.search("").to_a
    assert_empty ControlledVocabulary::Variant.search(nil).to_a
  end

  test "search returns nothing when no variant matches" do
    term = create(:controlled_vocabulary_term)
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    assert_empty ControlledVocabulary::Variant.search("wheat").to_a
  end
end
