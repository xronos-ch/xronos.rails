# == Schema Information
#
# Table name: references
# Database name: primary
#
#  id         :bigint           not null, primary key
#  bibtex     :text
#  short_ref  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
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
    dupe = create(:reference, short_ref: "Bronk Ramsey 2009")

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
    dupe.save!

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
    dupe.save!

    assert_predicate dupe, :superseded?
    # Canonical's citation remains; dupe's collision is destroyed
    assert_equal 1, Citation.where(reference_id: canonical.id, citing: site).count
    assert_equal 0, Citation.where(reference_id: dupe.id).count
  end

  test "reassigns sources to the canonical on create" do
    canonical = create(:reference, short_ref: "Bronk Ramsey 2009")
    dupe = build(:reference, short_ref: "Bronk Ramsey 2009")
    dupe.sources << build(:source, reference: dupe)
    dupe.save!

    assert_predicate dupe, :superseded?
    assert_equal 0, Source.where(reference_id: dupe.id).count
    assert_equal 1, Source.where(reference_id: canonical.id).count
  end
end
