require "test_helper"

class HasControlledTermsTest < ActiveSupport::TestCase
  # DDL in setup is not transactional
  self.use_transactional_tests = false

  setup do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :widgets, force: true do |t|
          t.string :colour
          t.string :material
        end
      end
    end
  end

  teardown do
    ActiveRecord::Base.connection.drop_table(:widgets, if_exists: true)
    ActiveRecord::Base.connection.execute "TRUNCATE TABLE controlled_vocabulary_variants, controlled_vocabulary_terms, controlled_vocabularies RESTART IDENTITY"
  end

  class Widget < ApplicationRecord
    self.table_name = "widgets"

    include HasControlledTerms

    controlled_term :colour,   vocabulary: "colours"
    controlled_term :material, vocabulary: "materials"
  end

  setup do
    @colours   = create(:controlled_vocabulary, name: "colours")
    @materials = create(:controlled_vocabulary, name: "materials")
    @red       = create(:controlled_vocabulary_term, vocabulary: @colours,   name: "Red")
    @blue      = create(:controlled_vocabulary_term, vocabulary: @colours,   name: "Blue")
    @oak       = create(:controlled_vocabulary_term, vocabulary: @materials, name: "Oak")
    @pine      = create(:controlled_vocabulary_term, vocabulary: @materials, name: "Pine",
                        ontology_name: "PO", ontology_id: "PO:0000048")
  end

  # --- controlled? ---

  test "controlled? returns true for an exact name match" do
    widget = Widget.new(colour: "Red")

    assert widget.controlled?(:colour)
    assert widget.colour_controlled?
  end

  test "controlled? returns false for a case-mismatched value" do
    widget = Widget.new(colour: "red")

    assert_not widget.controlled?(:colour)
    assert_not widget.colour_controlled?
  end

  test "controlled? does not consult variants" do
    create(:controlled_vocabulary_variant, term: @red, value: "Scarlet")
    widget = Widget.new(colour: "Scarlet")

    assert_not widget.colour_controlled?
  end

  test "controlled? returns false for a value with no matching term" do
    widget = Widget.new(colour: "Mauve")

    assert_not widget.controlled?(:colour)
    assert_not widget.colour_controlled?
  end

  test "controlled? returns false for a blank or nil value" do
    assert_not Widget.new(colour: nil).colour_controlled?
    assert_not Widget.new(colour: "").colour_controlled?
    assert_not Widget.new(colour: "   ").colour_controlled?
  end

  test "controlled? only looks at the value's vocabulary, not others" do
    widget = Widget.new(colour: "Oak")

    assert_not widget.colour_controlled?
  end

  # --- vocabulary_for ---

  test "vocabulary_for returns the declared vocabulary" do
    widget = Widget.new

    assert_equal @colours, widget.vocabulary_for(:colour)
    assert_equal @colours, widget.colour_vocabulary
  end

  test "vocabulary_for returns nil for an undeclared attribute" do
    widget = Widget.new

    assert_nil widget.vocabulary_for(:shape)
  end

  test "vocabulary_for returns nil when the vocabulary record does not exist" do
    @colours.destroy

    assert_nil Widget.new(colour: "Red").colour_vocabulary
  end

  # --- term_for ---

  test "term_for returns the matched term" do
    widget = Widget.new(colour: "Red")

    assert_equal @red, widget.term_for(:colour)
    assert_equal @red, widget.colour_term
  end

  test "term_for returns nil for a case-mismatched value" do
    widget = Widget.new(colour: "red")

    assert_nil widget.term_for(:colour)
  end

  test "term_for does not consult variants" do
    create(:controlled_vocabulary_variant, term: @red, value: "Scarlet")
    widget = Widget.new(colour: "Scarlet")

    assert_nil widget.term_for(:colour)
  end

  test "term_for returns nil when no term matches" do
    widget = Widget.new(colour: "Mauve")

    assert_nil widget.term_for(:colour)
    assert_nil widget.colour_term
  end

  test "term_for returns nil for a blank value" do
    assert_nil Widget.new(colour: nil).colour_term
    assert_nil Widget.new(colour: "").colour_term
  end

  test "term_for returns nil when the vocabulary does not exist" do
    @materials.destroy

    assert_nil Widget.new(material: "Oak").term_for(:material)
  end

  # --- terms_for ---

  test "terms_for returns all matching terms" do
    widget = Widget.new(colour: "Red")

    assert_equal [@red], widget.terms_for(:colour)
    assert_equal [@red], widget.colour_terms
  end

  test "terms_for returns multiple terms that share a name across ontologies" do
    uberon_red = create(:controlled_vocabulary_term, vocabulary: @colours,
      name: "Red", ontology_name: "UBERON", ontology_id: "UBERON:0000376")
    widget = Widget.new(colour: "Red")

    # Both terms are returned, ordered by ontology_name (UBERON first),
    # with terms that have no ontology metadata sorted last.
    assert_equal [uberon_red, @red], widget.terms_for(:colour)
  end

  test "terms_for returns an empty array when no term matches" do
    widget = Widget.new(colour: "Mauve")

    assert_equal [], widget.terms_for(:colour)
    assert_equal [], widget.colour_terms
  end

  test "terms_for returns an empty array for a blank value" do
    assert_equal [], Widget.new(colour: nil).colour_terms
    assert_equal [], Widget.new(colour: "").colour_terms
  end

  test "terms_for returns an empty array when the vocabulary does not exist" do
    @materials.destroy

    assert_equal [], Widget.new(material: "Oak").terms_for(:material)
  end

  # --- ontologies_for ---

  test "ontologies_for returns [{name, id, url}] for a term with ontology metadata" do
    widget = Widget.new(material: "Pine")
    expected_url = "http://purl.obolibrary.org/obo/PO_0000048"

    assert_equal [{ name: "PO", id: "PO:0000048", url: expected_url }],
                 widget.ontologies_for(:material)
    assert_equal widget.ontologies_for(:material), widget.material_ontologies
  end

  test "ontologies_for returns an empty array when the term has no ontology metadata" do
    widget = Widget.new(material: "Oak")

    assert_equal [], widget.ontologies_for(:material)
  end

  test "ontologies_for returns an empty array when no term matches" do
    widget = Widget.new(material: "Bamboo")

    assert_equal [], widget.ontologies_for(:material)
  end

  test "ontologies_for returns an empty array for a blank value" do
    assert_equal [], Widget.new(material: nil).material_ontologies
  end

  test "ontologies_for returns one entry per matching term" do
    # Two terms with the same name, each with their own ontology metadata.
    # ontologies_for should expose both.
    @red.update!(ontology_name: "PO", ontology_id: "PO:0000086")
    uberon_red = create(:controlled_vocabulary_term, vocabulary: @colours,
      name: "Red", ontology_name: "UBERON", ontology_id: "UBERON:0000376")
    widget = Widget.new(colour: "Red")

    assert_equal 2, widget.ontologies_for(:colour).length
    names = widget.ontologies_for(:colour).map { |o| o[:name] }
    assert_includes names, "PO"
    assert_includes names, "UBERON"
  end

  test "ontologies_for skips terms with no ontology metadata" do
    # @red has no ontology_name/ontology_id, so it contributes nothing
    # to the returned array even when it matches.
    widget = Widget.new(colour: "Red")

    assert_equal [], widget.ontologies_for(:colour)
  end

  # --- resolve_variant_for ---

  test "resolve_variant_for returns the term for a known variant via the declared vocabulary" do
    create(:controlled_vocabulary_variant, term: @red, value: "scarlet")
    widget = Widget.new(colour: "scarlet")

    assert_equal @red, widget.resolve_variant_for(:colour, "scarlet")
  end

  test "resolve_variant_for is case-insensitive" do
    create(:controlled_vocabulary_variant, term: @red, value: "scarlet")
    widget = Widget.new

    assert_equal @red, widget.resolve_variant_for(:colour, "SCARLET")
  end

  test "resolve_variant_for returns nil when no variant matches" do
    widget = Widget.new

    assert_nil widget.resolve_variant_for(:colour, "mauve")
  end

  test "resolve_variant_for returns nil for blank input" do
    widget = Widget.new

    assert_nil widget.resolve_variant_for(:colour, nil)
    assert_nil widget.resolve_variant_for(:colour, "")
    assert_nil widget.resolve_variant_for(:colour, "   ")
  end

  test "resolve_variant_for returns nil when the vocabulary does not exist" do
    @colours.destroy
    widget = Widget.new

    assert_nil widget.resolve_variant_for(:colour, "anything")
  end

  test "resolve_variant_for returns nil for an undeclared attribute" do
    widget = Widget.new

    assert_nil widget.resolve_variant_for(:shape, "anything")
  end

  test "resolve_variant_for does not fall back to term-name matching" do
    widget = Widget.new(colour: "Red")

    assert_nil widget.resolve_variant_for(:colour, "Red")
    assert_nil widget.resolve_variant_for(:colour, "red")
  end

  # --- parameterised vs generated equivalence ---

  test "generated instance methods mirror the parameterised ones" do
    widget = Widget.new(colour: "Red", material: "Pine")

    assert_equal widget.controlled?(:colour),   widget.colour_controlled?
    assert_equal widget.vocabulary_for(:colour), widget.colour_vocabulary
    assert_equal widget.term_for(:material),    widget.material_term
    assert_equal widget.terms_for(:material),   widget.material_terms
    assert_equal widget.ontologies_for(:material), widget.material_ontologies
  end

  # --- scopes ---

  test "controlled scope returns records whose value matches a term" do
    matched   = Widget.create!(colour: "Red", material: "Oak")
    unmatched = Widget.create!(colour: "Mauve", material: "Bamboo")

    assert_includes Widget.controlled(:colour), matched
    assert_not_includes Widget.controlled(:colour), unmatched
  end

  test "controlled scope is case-sensitive" do
    matched   = Widget.create!(colour: "Red", material: "oak")
    _mismatch = Widget.create!(colour: "red", material: "oak")

    assert_includes     Widget.controlled(:colour), matched
    assert_not_includes Widget.controlled(:colour), _mismatch
  end

  test "controlled scope does not consult variants" do
    create(:controlled_vocabulary_variant, term: @red, value: "Scarlet")
    _matched = Widget.create!(colour: "Scarlet", material: "oak")

    assert_equal 0, Widget.controlled(:colour).count
  end

  test "controlled scope is empty when the vocabulary has no terms" do
    @colours.terms.destroy_all
    _matched = Widget.create!(colour: "Red", material: "oak")

    assert_equal 0, Widget.controlled(:colour).count
  end

  test "controlled scope returns none when the vocabulary does not exist" do
    @colours.destroy
    _any = Widget.create!(colour: "Red", material: "oak")

    assert_equal 0, Widget.controlled(:colour).count
  end

  test "uncontrolled scope returns records whose value does not match a term" do
    matched   = Widget.create!(colour: "Red", material: "Oak")
    unmatched = Widget.create!(colour: "Mauve", material: "Bamboo")

    assert_includes Widget.uncontrolled(:colour), unmatched
    assert_not_includes Widget.uncontrolled(:colour), matched
  end

  test "uncontrolled scope returns all when the vocabulary does not exist" do
    @colours.destroy
    _any = Widget.create!(colour: "Red", material: "oak")

    assert_equal Widget.count, Widget.uncontrolled(:colour).count
  end

  test "generated scopes mirror the parameterised scopes" do
    matched   = Widget.create!(colour: "Red", material: "Oak")
    unmatched = Widget.create!(colour: "Mauve", material: "Bamboo")

    assert_equal Widget.controlled(:colour).pluck(:id).sort,   Widget.controlled_colour.pluck(:id).sort
    assert_equal Widget.uncontrolled(:colour).pluck(:id).sort, Widget.uncontrolled_colour.pluck(:id).sort
  end

  test "scopes only consider the declared attribute, not the whole record" do
    create(:controlled_vocabulary_term, vocabulary: @colours, name: "Mauve")
    widget = Widget.create!(colour: "Mauve", material: "Oak")

    assert_includes     Widget.controlled(:colour),   widget
    assert_includes     Widget.controlled(:material), widget
  end

  # --- error handling ---

  test "controlled scope raises if the attribute is not declared" do
    assert_raises(ArgumentError) do
      Widget.controlled(:shape)
    end
  end

  test "uncontrolled scope raises if the attribute is not declared" do
    assert_raises(ArgumentError) do
      Widget.uncontrolled(:shape)
    end
  end
end
