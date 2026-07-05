# == Schema Information
#
# Table name: citations
# Database name: primary
#
#  id           :bigint           not null, primary key
#  citing_type  :string
#  citing_id    :bigint
#  reference_id :bigint
#
# Indexes
#
#  index_citations_on_citing                (citing_type,citing_id)
#  index_citations_on_citing_and_reference  (citing_type,citing_id,reference_id) UNIQUE
#  index_citations_on_reference_id          (reference_id)
#
require "test_helper"

class CitationTest < ActiveSupport::TestCase
  test "does not allow duplicate citations for the same reference and citing record" do
    citation = create(:citation)

    duplicate = build(
      :citation,
      reference: citation.reference,
      citing: citation.citing
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference], "has already been cited for this record"
  end

  test "destroying the last citation deletes its reference" do
    reference = create(:reference)
    citation  = create(:citation, reference: reference)

    assert_difference "Reference.count", -1 do
      citation.destroy
    end

    assert_nil Reference.find_by(id: reference.id),
      "Expected reference to be deleted when its last citation is destroyed"
  end

  test "destroying a citation does not delete a reference with remaining citations" do
    reference  = create(:reference)
    citation_1 = create(:citation, reference: reference)
    citation_2 = create(:citation, reference: reference)

    assert_difference "Citation.count", -1 do
      citation_1.destroy
    end

    assert Reference.exists?(reference.id),
      "Expected reference with remaining citations not to be deleted"

    assert_equal 1, reference.reload.citations.count
  end

  #
  # Citation.reassign_all_to!
  #

  test "reassign_all_to! moves citations from one Reference to another" do
    canonical = create(:reference)
    dupe      = create(:reference)
    site      = create(:site)
    create(:citation, reference: dupe, citing: site)

    Citation.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 0, Citation.where(reference_id: dupe.id).count
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site).count
  end

  test "reassign_all_to! moves citations from one Site to another" do
    reference = create(:reference)
    canonical = create(:site)
    dupe      = create(:site)
    create(:citation, reference: reference, citing: dupe)

    Citation.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 0, Citation.where(citing_type: "Site", citing_id: dupe.id).count
    assert_equal 1, Citation.where(citing_type: "Site", citing_id: canonical.id, reference: reference).count
  end

  test "reassign_all_to! destroys colliding citations instead of raising" do
    canonical = create(:reference)
    dupe      = create(:reference)
    site      = create(:site)
    create(:citation, reference: canonical, citing: site)
    create(:citation, reference: dupe, citing: site)

    assert_difference "Citation.count", -1 do
      Citation.reassign_all_to!(from: dupe, to: canonical)
    end

    # The canonical's citation remains
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site).count
    # The dupe's citation is gone
    assert_equal 0, Citation.where(reference_id: dupe.id).count
  end

  test "reassign_all_to! mixes reassignment and destruction in one call" do
    canonical = create(:reference)
    dupe      = create(:reference)
    site_a    = create(:site)
    site_b    = create(:site)
    # site_a cites both — collides on the canonical
    create(:citation, reference: canonical, citing: site_a)
    create(:citation, reference: dupe, citing: site_a)
    # site_b only cites the dupe — will be reassigned
    create(:citation, reference: dupe, citing: site_b)

    result = Citation.reassign_all_to!(from: dupe, to: canonical)

    assert_equal 1, result[:reassigned]
    assert_equal 1, result[:destroyed_collisions]
    # site_a citation remains (canonical's); site_b citation now points at canonical
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site_a).count
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site_b).count
    assert_equal 0, Citation.where(reference_id: dupe.id).count
  end

  test "reassign_all_to! raises when from and to are different classes" do
    reference = create(:reference)
    site      = create(:site)

    assert_raises(ArgumentError) { Citation.reassign_all_to!(from: reference, to: site) }
  end

  test "reassign_all_to! raises when to is not persisted" do
    reference = create(:reference)
    new_ref   = Reference.new

    assert_raises(ArgumentError) { Citation.reassign_all_to!(from: reference, to: new_ref) }
  end

  test "reassign_all_to! raises when from and to are the same record" do
    reference = create(:reference)

    assert_raises(ArgumentError) { Citation.reassign_all_to!(from: reference, to: reference) }
  end

  test "reassign_all_to! is a no-op when there are no citations" do
    canonical = create(:reference)
    dupe      = create(:reference)

    assert_no_difference "Citation.count" do
      result = Citation.reassign_all_to!(from: dupe, to: canonical)
      assert_equal 0, result[:reassigned]
      assert_equal 0, result[:destroyed_collisions]
    end
  end

end
