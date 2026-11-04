# == Schema Information
#
# Table name: references
# Database name: primary
#
#  id         :bigint           not null, primary key
#  csl        :jsonb
#  doi        :string
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_references_on_doi        (doi)
#  index_references_on_short_ref  (short_ref)
#
require "test_helper"

class ReferenceTest < ActiveSupport::TestCase
  test "destroying a reference destroys its citations" do
    reference = create(:reference)
    create_list(:citation, 2, reference: reference)

    assert_dependent_destroy(reference, :citations, count: 2)
  end

  #
  # Deduplication
  #

  test "auto-merges on create when an exact duplicate exists" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")

    # Bypass `validate :no_exact_duplicate, on: :create` to exercise
    # the after_save merge path in isolation.
    dupe = build(:reference, short_ref: "Bronk Ramsey 2009")
    dupe.save(validate: false)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test "auto-merges on update when an update creates a duplicate" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")
    other = create(:reference, short_ref: "Reimer et al 2004")

    other.update!(short_ref: "Bronk Ramsey 2009")

    assert_predicate other, :superseded?
    assert_equal canonical.id, other.merged_into_id
  end

  test "does not auto-merge when short_ref is unique" do
    create(:reference, short_ref: "Bronk Ramsey 2009")
    other = create(:reference, short_ref: "Reimer et al 2004")

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test "reassigns non-colliding citations to the canonical on create" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")
    site_a    = create(:site)
    site_b    = create(:site)
    # Citations created AFTER the canonical, on the would-be dupe,
    # should be reassigned when the dupe is auto-merged on save.
    dupe = build(:reference, short_ref: "Bronk Ramsey 2009")
    dupe.citations << build(:citation, reference: dupe, citing: site_a)
    dupe.citations << build(:citation, reference: dupe, citing: site_b)
    dupe.save(validate: false)

    assert_predicate dupe, :superseded?
    assert_equal 0, Citation.where(reference_id: dupe.id).count
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site_a).count
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site_b).count
  end

  test "destroys colliding citations on create" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")
    site      = create(:site)
    # Both records cite the same site — this is the collision case.
    create(:citation, reference: canonical, citing: site)

    dupe = build(:reference, short_ref: "Bronk Ramsey 2009")
    dupe.citations << build(:citation, reference: dupe, citing: site)
    dupe.save(validate: false)

    assert_predicate dupe, :superseded?
    # Canonical's citation remains; dupe's collision is destroyed
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site).count
    assert_equal 0, Citation.where(reference_id: dupe.id).count
  end

  test "reassigns sources to the canonical on create" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")
    dupe = build(:reference, short_ref: "Bronk Ramsey 2009")
    dupe.sources << build(:source, reference: dupe)
    dupe.save(validate: false)

    assert_predicate dupe, :superseded?
    assert_equal 0, Source.where(reference_id: dupe.id).count
    assert_equal 1, Source.where(reference_id: canonical.id).count
  end

  #
  # Memoization
  #

  test 'render_citation is memoized' do
    reference = create(:reference)

    result1 = reference.render_citation
    result2 = reference.render_citation

    assert_same result1, result2
  end

  #
  # Rendering
  #

  test 'render generates an APA bibliography from CSL' do
    reference = create(:reference, csl: [journal_article])

    assert_includes reference.render, 'Doe'
    assert_includes reference.render, 'Test Article'
    assert_includes reference.render, '2020'
  end

  test 'render returns a placeholder when CSL is empty' do
    reference = create(:reference, csl: nil)

    assert_equal 'No bibliographic information available.', reference.render
  end

  test 'render_citation generates an inline citation from CSL' do
    reference = create(:reference, csl: [journal_article])

    assert_includes reference.render_citation, 'Doe'
    assert_includes reference.render_citation, '2020'
  end

  test 'render_citation falls back to short_ref when CSL is empty' do
    reference = create(:reference, short_ref: 'Doe2020', csl: nil)

    assert_equal 'Doe2020', reference.render_citation
  end

  #
  # Formatting
  #

  test 'format_json returns the CSL items as JSON' do
    reference = create(:reference, csl: [journal_article])

    assert_equal [journal_article], JSON.parse(reference.format_json)
  end

  test 'format_yaml returns the CSL items as YAML' do
    reference = create(:reference, csl: [journal_article])

    assert_equal [journal_article], YAML.safe_load(reference.format_yaml)
  end

  test 'format_bibtex converts CSL to BibTeX' do
    reference = create(:reference, csl: [journal_article])

    assert_includes reference.format_bibtex, 'Doe, Jane'
    assert_includes reference.format_bibtex, '2020'
  end

  test 'format_ris converts CSL to RIS' do
    reference = create(:reference, csl: [journal_article])

    assert_includes reference.format_ris, 'TY  - JOUR'
    assert_includes reference.format_ris, 'AU  - Doe, Jane'
  end

  test 'export formats omit internal QA keys' do
    reference = create(:reference, csl: [journal_article.merge('_raw_bibtex' => '@misc{raw junk}')])

    assert_not_includes reference.format_bibtex, 'raw junk'
    assert_not_includes reference.format_ris, 'raw junk'
  end

  #
  # DOI extraction
  #

  test 'doi is extracted from CSL on save' do
    reference = create(:reference, csl: [journal_article])

    assert_equal '10.1234/test', reference.doi
  end

  test 'doi extraction strips URL prefixes and downcases' do
    reference = create(:reference, csl: [journal_article.merge('DOI' => ' https://doi.org/10.1234/ABC ')])

    assert_equal '10.1234/abc', reference.doi
  end

  test 'doi extraction strips the doi: prefix' do
    reference = create(:reference, csl: [journal_article.merge('DOI' => 'doi:10.1234/X')])

    assert_equal '10.1234/x', reference.doi
  end

  test 'doi is nil when CSL has no DOI' do
    reference = create(:reference, :without_doi)

    assert_nil reference.doi
  end

  test 'doi is taken from the first item with a DOI' do
    reference = create(:reference, csl: [
      journal_article.except('DOI'),
      journal_article.merge('id' => 'second', 'DOI' => '10.5678/second')
    ])

    assert_equal '10.5678/second', reference.doi
  end

  test 'doi is re-extracted when CSL changes' do
    reference = create(:reference, csl: [journal_article])
    reference.update!(csl: [journal_article.except('DOI')])

    assert_nil reference.doi
  end

  #
  # Issues
  #

  test 'missing_bibtex is not registered as an issue' do
    assert_not_includes Reference.issues, :missing_bibtex
  end

  private

  def journal_article
    {
      'id' => 'doe2020',
      'type' => 'article-journal',
      'author' => [{ 'family' => 'Doe', 'given' => 'Jane' }],
      'title' => 'Test Article',
      'container-title' => 'Test Journal',
      'issued' => { 'date-parts' => [[2020]] },
      'DOI' => '10.1234/test'
    }
  end
end
