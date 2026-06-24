# == Schema Information
#
# Table name: controlled_vocabularies
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_controlled_vocabularies_on_name  (name) UNIQUE
#
require "test_helper"

class ControlledVocabularyTest < ActiveSupport::TestCase
  test "factory creates a valid vocabulary" do
    assert create(:controlled_vocabulary).valid?
  end

  test "requires a name" do
    vocabulary = build(:controlled_vocabulary, name: nil)

    assert_not vocabulary.valid?
    assert_includes vocabulary.errors[:name], "can't be blank"
  end

  test "requires a unique name" do
    create(:controlled_vocabulary, name: "part_of_organism")
    duplicate = build(:controlled_vocabulary, name: "part_of_organism")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "self[name] looks up a vocabulary by name" do
    create(:controlled_vocabulary, name: "part_of_organism")

    assert_equal "part_of_organism", ControlledVocabulary["part_of_organism"].name
  end

  test "self[name] raises if the vocabulary does not exist" do
    assert_raises(ActiveRecord::RecordNotFound) do
      ControlledVocabulary["nonexistent"]
    end
  end

  test "match returns the term linked to a known variant (case-insensitive)" do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")
    create(:controlled_vocabulary_variant, term: term, value: "maize cob")

    assert_equal term, vocabulary.match("Maize Cob")
  end

  test "match returns the term for an exact name match (case-insensitive)" do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cranium")

    assert_equal term, vocabulary.match("CRANIUM")
  end

  test "match prefers a variant match over an exact name match" do
    vocabulary = create(:controlled_vocabulary)
    exact = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")
    via_variant = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob (maize)")
    create(:controlled_vocabulary_variant, term: via_variant, value: "cob")

    assert_equal via_variant, vocabulary.match("Cob")
  end

  test "match returns nil for unknown input" do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")

    assert_nil vocabulary.match("Kob")
  end

  test "match returns nil for blank or nil input" do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: "Cob")

    assert_nil vocabulary.match(nil)
    assert_nil vocabulary.match("")
    assert_nil vocabulary.match("   ")
  end

  test "match only looks up terms in this vocabulary" do
    vocabulary = create(:controlled_vocabulary)
    other = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: other, name: "Cob")

    assert_nil vocabulary.match("Cob")
    assert_equal term, other.match("Cob")
  end

  test "destroying a vocabulary cascades to its terms and their variants" do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary)
    create(:controlled_vocabulary_variant, term: term)

    vocabulary.destroy!

    assert_raises(ActiveRecord::RecordNotFound) { term.reload }
  end
end
