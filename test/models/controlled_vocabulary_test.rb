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

  # --- compute_seed_summary / apply_seed ---

  def parsed_term(id:, name:, synonyms: [], alt_ids: [], definition: nil)
    { id: id, name: name, synonyms: synonyms, alt_ids: alt_ids, definition: definition }
  end

  def synonym(text, type = 'EXACT', language: nil)
    { text: text, type: type, language: language }
  end

  # --- filters ---

  def term(subsets: [], is_obsolete: false, name: 'thing', id: 'X:1')
    { id: id, name: name, subsets: subsets, is_obsolete: is_obsolete, synonyms: [], alt_ids: [] }
  end

  # --- uberon_filter ---

  test 'uberon_filter keeps terms in organ_slim' do
    assert ControlledVocabulary.uberon_filter.call(term(subsets: ['organ_slim']))
  end

  test 'uberon_filter keeps terms in uberon_slim' do
    assert ControlledVocabulary.uberon_filter.call(term(subsets: ['uberon_slim']))
  end

  test 'uberon_filter keeps terms in both slim subsets' do
    assert ControlledVocabulary.uberon_filter.call(term(subsets: %w[organ_slim uberon_slim]))
  end

  test 'uberon_filter drops terms outside the slim subsets' do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: ['other_slim']))
  end

  test 'uberon_filter drops terms in non_informative even if in a slim subset' do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: %w[organ_slim non_informative]))
  end

  test 'uberon_filter drops terms in grouping_class even if in a slim subset' do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: %w[uberon_slim grouping_class]))
  end

  test 'uberon_filter drops terms in upper_level even if in a slim subset' do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: %w[organ_slim upper_level]))
  end

  test 'uberon_filter drops obsoletes regardless of subset' do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: ['organ_slim'], is_obsolete: true))
  end

  test "uberon_filter drops 'whole organism' even if in organ_slim" do
    assert_not ControlledVocabulary.uberon_filter.call(term(subsets: ['organ_slim'], name: 'whole organism'))
  end

  test "uberon_filter drops 'multicellular organism' even if in organ_slim" do
    assert_not ControlledVocabulary.uberon_filter.call(
      term(subsets: ['organ_slim'], name: 'multicellular organism')
    )
  end

  # --- po_filter ---

  test 'po_filter keeps terms in the reference subset' do
    assert ControlledVocabulary.po_filter.call(term(subsets: ['reference']))
  end

  test 'po_filter drops terms outside the reference subset' do
    assert_not ControlledVocabulary.po_filter.call(term(subsets: ['other']))
  end

  test 'po_filter drops obsoletes regardless of subset' do
    assert_not ControlledVocabulary.po_filter.call(term(subsets: ['reference'], is_obsolete: true))
  end

  test "po_filter drops 'whole plant' (PO:0000003) even if in reference" do
    assert_not ControlledVocabulary.po_filter.call(
      term(subsets: ['reference'], id: 'PO:0000003', name: 'whole plant')
    )
  end

  # --- apply_seed ---

  test 'apply_seed creates the vocabulary if it does not exist' do
    assert_nil ControlledVocabulary.find_by(name: 'part_of_organism')

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'uterine cervix')]
    )

    assert ControlledVocabulary.find_by(name: 'part_of_organism').present?
  end

  test 'apply_seed inserts a new term with ontology_id and name' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'uterine cervix')]
    )

    term = ControlledVocabulary::Term.find_by(ontology_name: 'UBERON', ontology_id: 'UBERON:0000002')
    assert_equal 'uterine cervix', term.name
    assert_equal 'part_of_organism', term.vocabulary.name
  end

  test 'apply_seed refreshes the name when a term is renamed in the source' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'uterine cervix')]
    )

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'neck of uterus')]
    )

    term = ControlledVocabulary::Term.find_by!(ontology_name: 'UBERON', ontology_id: 'UBERON:0000002')
    assert_equal 'neck of uterus', term.name
    assert_equal 1, ControlledVocabulary::Term.where(ontology_name: 'UBERON').count
  end

  test 'apply_seed deletes a term that is no longer in the source' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [
        parsed_term(id: 'UBERON:0000001', name: 'alpha'),
        parsed_term(id: 'UBERON:0000002', name: 'beta')
      ]
    )

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'beta')]
    )

    assert_nil ControlledVocabulary::Term.find_by(ontology_id: 'UBERON:0000001')
    assert ControlledVocabulary::Term.find_by(ontology_id: 'UBERON:0000002').present?
  end

  test 'apply_seed deletes only terms of the given ontology' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000001', name: 'alpha')]
    )
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'PO',
      terms: [parsed_term(id: 'PO:0000003', name: 'whole plant')]
    )

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: []
    )

    assert_nil ControlledVocabulary::Term.find_by(ontology_id: 'UBERON:0000001')
    assert ControlledVocabulary::Term.find_by(ontology_id: 'PO:0000003').present?
  end

  test 'apply_seed seeds EXACT and RELATED synonyms as variants' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(
        id: 'UBERON:0000002',
        name: 'uterine cervix',
        synonyms: [
          synonym('uterine cervix', 'EXACT'),
          synonym('cervix', 'BROAD'),
          synonym('canalis cervicis uteri', 'EXACT')
        ]
      )]
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    values = term.variants.pluck(:value)

    assert_includes values, 'uterine cervix'
    assert_includes values, 'canalis cervicis uteri'
    assert_not_includes values, 'cervix'
  end

  test 'apply_seed seeds alt_id values as variants' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'PO',
      terms: [parsed_term(
        id: 'PO:0000002',
        name: 'anther wall',
        alt_ids: ['PO:0006445', 'PO:0006477']
      )]
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'PO:0000002')
    assert_equal ['PO:0006445', 'PO:0006477'], term.variants.pluck(:value).sort
  end

  test 'apply_seed replaces variants on each re-seed' do
    terms = [parsed_term(
      id: 'UBERON:0000002',
      name: 'uterine cervix',
      synonyms: [synonym('cervix uteri', 'EXACT')]
    )]

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: terms
    )
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: terms
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    assert_equal 1, term.variants.count
  end

  test 'apply_seed dedupes variant values case-insensitively' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(
        id: 'UBERON:0000002',
        name: 'uterine cervix',
        synonyms: [
          synonym('cervix', 'EXACT'),
          synonym('CERVIX', 'RELATED'),
          synonym('Cervix', 'EXACT')
        ]
      )]
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    assert_equal 1, term.variants.count
  end

  test 'apply_seed is a no-op on a second run with the same input' do
    terms = [parsed_term(id: 'UBERON:0000002', name: 'uterine cervix')]

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism', ontology_name: 'UBERON', terms: terms
    )
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism', ontology_name: 'UBERON', terms: terms
    )

    assert_equal 1, ControlledVocabulary::Term.count
  end

  test 'apply_seed cascades variants when deleting a term' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(
        id: 'UBERON:0000001',
        name: 'alpha',
        synonyms: [synonym('alpha-1', 'EXACT')]
      )]
    )
    term_id = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000001').id
    assert ControlledVocabulary::Variant.where(controlled_vocabulary_term_id: term_id).any?

    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: []
    )

    assert_equal 0, ControlledVocabulary::Variant.where(controlled_vocabulary_term_id: term_id).count
  end

  # --- compute_seed_summary ---

  def write_obo(content)
    f = Tempfile.new(['seed-test', '.obo'])
    f.write(content)
    f.close
    f.path
  end

  test 'compute_seed_summary returns a SeedPlan with summary and kept_terms' do
    path = write_obo(<<~OBO)
      format-version: 1.2
      [Term]
      id: TEST:0000001
      name: alpha
      def: "First term." [curator]
    OBO

    plan = ControlledVocabulary.compute_seed_summary(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      obo_path:        path,
      filter:          ->(_) { true }
    )

    assert_instance_of ControlledVocabulary::SeedPlan, plan
    assert_equal 1, plan.summary[:kept]
    assert_equal 1, plan.kept_terms.size
    assert_equal 'alpha', plan.kept_terms.first[:name]
  end

  test 'compute_seed_summary applies the filter to the stream' do
    path = write_obo(<<~OBO)
      format-version: 1.2
      [Term]
      id: TEST:0000001
      name: alpha

      [Term]
      id: TEST:0000002
      name: beta
    OBO

    plan = ControlledVocabulary.compute_seed_summary(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      obo_path:        path,
      filter:          ->(t) { t[:name] == 'alpha' }
    )

    assert_equal 1, plan.summary[:kept]
    assert_equal 'alpha', plan.kept_terms.first[:name]
  end

  test 'compute_seed_summary does not write to the database' do
    path = write_obo(<<~OBO)
      format-version: 1.2
      [Term]
      id: TEST:0000001
      name: alpha
    OBO

    vocab_count_before = ControlledVocabulary.count
    term_count_before  = ControlledVocabulary::Term.count

    ControlledVocabulary.compute_seed_summary(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      obo_path:        path,
      filter:          ->(_) { true }
    )

    assert_equal vocab_count_before, ControlledVocabulary.count
    assert_equal term_count_before,  ControlledVocabulary::Term.count
  end

  test 'compute_seed_summary reports what would be inserted, updated, and deleted' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      terms: [
        parsed_term(id: 'UBERON:0000001', name: 'alpha'),
        parsed_term(id: 'UBERON:0000002', name: 'beta')
      ]
    )

    path = write_obo(<<~OBO)
      format-version: 1.2
      [Term]
      id: UBERON:0000002
      name: beta

      [Term]
      id: UBERON:0000003
      name: gamma
    OBO

    plan = ControlledVocabulary.compute_seed_summary(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      obo_path:        path,
      filter:          ->(_) { true }
    )

    assert_equal 2, plan.summary[:kept]
    assert_equal 1, plan.summary[:inserted]  # UBERON:0000003
    assert_equal 1, plan.summary[:updated]   # UBERON:0000002
    assert_equal 1, plan.summary[:deleted]   # UBERON:0000001
  end

  test 'compute_seed_summary reports variants_rebuilt from the parsed term' do
    path = write_obo(<<~OBO)
      format-version: 1.2
      [Term]
      id: TEST:0000001
      name: alpha
      synonym: "alpha (exact)" EXACT []
      synonym: "alpha-1" EXACT []
      alt_id: TEST:0000099
    OBO

    plan = ControlledVocabulary.compute_seed_summary(
      vocabulary_name: 'part_of_organism',
      ontology_name:   'UBERON',
      obo_path:        path,
      filter:          ->(_) { true }
    )

    assert_equal 3, plan.summary[:variants_rebuilt]
  end

  # --- description population ---

  def with_obo_def(id:, name:, definition:)
    Tempfile.create(['seed-test', '.obo']) do |f|
      f.write <<~OBO
        format-version: 1.2
        [Term]
        id: #{id}
        name: #{name}
        def: "#{definition}"
      OBO
      f.close
      ControlledVocabulary.apply_seed(
        vocabulary_name: 'part_of_organism',
        ontology_name: 'UBERON',
        terms: Obo::Parser.each_term(f.path).to_a
      )
    end
  end

  test 'apply_seed populates description from the parsed def' do
    with_obo_def(
      id: 'UBERON:0000002',
      name: 'uterine cervix',
      definition: 'The lower, narrow portion of the uterus.'
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    assert_equal 'The lower, narrow portion of the uterus.', term.description
  end

  test 'apply_seed stores nil for a term whose source has no def' do
    ControlledVocabulary.apply_seed(
      vocabulary_name: 'part_of_organism',
      ontology_name: 'UBERON',
      terms: [parsed_term(id: 'UBERON:0000002', name: 'uterine cervix')]
    )

    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    assert_nil term.description
  end

  test 'apply_seed refreshes the description on re-seed even when name is unchanged' do
    with_obo_def(
      id: 'UBERON:0000002',
      name: 'uterine cervix',
      definition: 'First definition.'
    )
    term = ControlledVocabulary::Term.find_by!(ontology_id: 'UBERON:0000002')
    assert_equal 'First definition.', term.description

    with_obo_def(
      id: 'UBERON:0000002',
      name: 'uterine cervix',
      definition: 'Second, updated definition.'
    )

    assert_equal 'Second, updated definition.', term.reload.description
  end
end
