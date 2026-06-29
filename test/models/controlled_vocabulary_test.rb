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
require 'test_helper'

class ControlledVocabularyTest < ActiveSupport::TestCase
  test 'factory creates a valid vocabulary' do
    assert create(:controlled_vocabulary).valid?
  end

  test 'requires a name' do
    vocabulary = build(:controlled_vocabulary, name: nil)

    assert_not vocabulary.valid?
    assert_includes vocabulary.errors[:name], "can't be blank"
  end

  test 'requires a unique name' do
    create(:controlled_vocabulary, name: 'part_of_organism')
    duplicate = build(:controlled_vocabulary, name: 'part_of_organism')

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], 'has already been taken'
  end

  test 'self[name] looks up a vocabulary by name' do
    create(:controlled_vocabulary, name: 'part_of_organism')

    assert_equal 'part_of_organism', ControlledVocabulary['part_of_organism'].name
  end

  test 'self[name] raises if the vocabulary does not exist' do
    assert_raises(ActiveRecord::RecordNotFound) do
      ControlledVocabulary['nonexistent']
    end
  end

  test 'match returns the term for an exact name match (case-sensitive)' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cranium')

    assert_equal term, vocabulary.match('Cranium')
  end

  test 'match returns nil for a case-mismatched name' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cranium')

    assert_nil vocabulary.match('cranium')
    assert_nil vocabulary.match('CRANIUM')
  end

  test 'match does not consult variants' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob')
    create(:controlled_vocabulary_variant, term: vocabulary.terms.first, value: 'maize cob')

    assert_nil vocabulary.match('Maize Cob')
    assert_nil vocabulary.match('maize cob')
  end

  test 'match returns nil for unknown input' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob')

    assert_nil vocabulary.match('Kob')
  end

  test 'match returns nil for blank or nil input' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob')

    assert_nil vocabulary.match(nil)
    assert_nil vocabulary.match('')
  end

  test 'match only looks up terms in this vocabulary' do
    vocabulary = create(:controlled_vocabulary)
    other = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: other, name: 'Cob')

    assert_nil vocabulary.match('Cob')
    assert_equal term, other.match('Cob')
  end

  test 'match is deterministic when multiple terms share a name' do
    # Two terms in the same vocabulary with the same name. PO (alphabetically
    # before UBERON) should win, and the lower id should break further ties.
    vocabulary = create(:controlled_vocabulary)
    uberon_term = create(:controlled_vocabulary_term, vocabulary: vocabulary,
      name: 'Cortex', ontology_name: 'UBERON', ontology_id: 'UBERON:0001850')
    po_term     = create(:controlled_vocabulary_term, vocabulary: vocabulary,
      name: 'Cortex', ontology_name: 'PO',     ontology_id: 'PO:0000055')

    assert_equal po_term, vocabulary.match('Cortex')
    assert_equal [po_term, uberon_term], vocabulary.matches('Cortex').to_a
  end

  # --- matches ---

  test 'matches returns all terms with the given name' do
    vocabulary = create(:controlled_vocabulary)
    cranium = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cranium')
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Femur')

    assert_equal [cranium], vocabulary.matches('Cranium').to_a
  end

  test 'matches returns multiple terms that share a name' do
    vocabulary = create(:controlled_vocabulary)
    uberon = create(:controlled_vocabulary_term, vocabulary: vocabulary,
      name: 'Cortex', ontology_name: 'UBERON', ontology_id: 'UBERON:0001850')
    po     = create(:controlled_vocabulary_term, vocabulary: vocabulary,
      name: 'Cortex', ontology_name: 'PO',     ontology_id: 'PO:0000055')

    results = vocabulary.matches('Cortex').to_a

    assert_equal [po, uberon], results
  end

  test 'matches returns an empty relation for unknown or blank input' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cranium')

    assert_empty vocabulary.matches('Kob').to_a
    assert_empty vocabulary.matches(nil).to_a
    assert_empty vocabulary.matches('').to_a
  end

  test 'matches does not consult variants' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_empty vocabulary.matches('maize cob').to_a
  end

  test 'destroying a vocabulary cascades to its terms and their variants' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary)
    create(:controlled_vocabulary_variant, term: term)

    vocabulary.destroy!

    assert_raises(ActiveRecord::RecordNotFound) { term.reload }
  end

  # --- resolve_variant ---

  test 'resolve_variant returns nil for nil or blank input' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_nil vocabulary.resolve_variant(nil)
    assert_nil vocabulary.resolve_variant('')
    assert_nil vocabulary.resolve_variant('   ')
  end

  test 'resolve_variant returns the term for a known variant match' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_equal term, vocabulary.resolve_variant('maize cob')
  end

  test 'resolve_variant is case-insensitive on the input' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_equal term, vocabulary.resolve_variant('MAIZE COB')
    assert_equal term, vocabulary.resolve_variant('Maize Cob')
  end

  test 'resolve_variant strips leading and trailing whitespace' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_equal term, vocabulary.resolve_variant('  maize cob  ')
  end

  test 'resolve_variant collapses internal whitespace runs' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_equal term, vocabulary.resolve_variant('maize  cob')
    assert_equal term, vocabulary.resolve_variant('  maize   cob  ')
    assert_equal term, vocabulary.resolve_variant("maize\tcob")
  end

  test 'resolve_variant does not ignore punctuation differences' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    # Regression guard: a future "be more aggressive" refactor would
    # break these. The current rule is squish only — punctuation stays.
    assert_nil vocabulary.resolve_variant('maize, cob')
    assert_nil vocabulary.resolve_variant('maize.cob')
  end

  test 'resolve_variant does not fall back to term-name matching' do
    vocabulary = create(:controlled_vocabulary)
    create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')

    assert_nil vocabulary.resolve_variant('Cob (maize)')
    assert_nil vocabulary.resolve_variant('cob (maize)')
  end

  test 'resolve_variant returns nil when no variant matches' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_nil vocabulary.resolve_variant('Kob')
  end

  test 'resolve_variant only looks in this vocabulary, not others' do
    vocabulary = create(:controlled_vocabulary)
    other = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: other, name: 'Cob (maize)')
    create(:controlled_vocabulary_variant, term: term, value: 'maize cob')

    assert_nil vocabulary.resolve_variant('maize cob')
    assert_equal term, other.resolve_variant('maize cob')
  end

  test 'resolve_variant returns nil if the matched variant was destroyed' do
    vocabulary = create(:controlled_vocabulary)
    term = create(:controlled_vocabulary_term, vocabulary: vocabulary, name: 'Cob (maize)')
    variant = create(:controlled_vocabulary_variant, term: term, value: 'maize cob')
    variant.destroy

    assert_nil vocabulary.resolve_variant('maize cob')
  end

  # --- search_variants ---

  test 'search_variants eager-loads the term to avoid N+1' do
    # Regression guard: Bullet flagged `ControlledVocabulary::Variant =>
    # [:term]` because every .term access on a returned variant fired a
    # SELECT. With .includes(:term) in the scope, ActiveRecord merges
    # the join into the variant query and pre-loads each term in one
    # round-trip; .term access on the returned records is a no-op.
    vocabulary = create(:controlled_vocabulary)
    3.times do |i|
      term = create(:controlled_vocabulary_term, vocabulary: vocabulary,
        name: "Term #{i}")
      create(:controlled_vocabulary_variant, term: term, value: 'match me')
    end

    variant_queries = 0
    term_queries = 0
    callback = ->(event_name, _start, _finish, _id, payload) do
      next unless event_name == 'sql.active_record'
      next if payload[:cached]
      sql = payload[:sql].to_s
      # The combined .includes(:term).joins(:term) yields a single SELECT
      # against controlled_vocabulary_variants that also pulls
      # controlled_vocabulary_terms columns. Anything other than that
      # one SELECT is an N+1.
      if sql.include?('FROM "controlled_vocabulary_variants"')
        variant_queries += 1
      elsif sql.include?('FROM "controlled_vocabulary_terms"')
        term_queries += 1
      end
    end
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      results = vocabulary.search_variants('match me')
      # Touch every result's term — this mirrors what the controller does.
      results.each { |v| v.term.name }
    end

    assert_equal 1, variant_queries,
      "expected exactly 1 variant query (with terms joined), got #{variant_queries}"
    assert_equal 0, term_queries,
      "expected 0 standalone term queries (N+1), got #{term_queries}"
  end
end
