# == Schema Information
#
# Table name: typos
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :integer
#  sample_id         :bigint
#
# Indexes
#
#  index_typos_on_name       (name)
#  index_typos_on_sample_id  (sample_id)
#
require "test_helper"

class TypoTest < ActiveSupport::TestCase
  test "destroying a typo destroys its citations" do
    typo = create(:typo, :with_citations, citations_count: 2)
    assert_dependent_destroy(typo, :citations, count: 2)
  end

  #
  # Deduplication
  #

  test "auto-merges on create when all key attrs match" do
    sample = create(:sample)
    canonical = create(:typo, sample: sample, name: "Roman Iron Age",
                                  approx_start_time: -550, approx_end_time: -350)
    dupe = create(:typo, sample: sample, name: "Roman Iron Age",
                              approx_start_time: -550, approx_end_time: -350)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test "auto-merges on update when an update creates a duplicate" do
    sample = create(:sample)
    canonical = create(:typo, sample: sample, name: "Roman Iron Age",
                                  approx_start_time: -550, approx_end_time: -350)
    other = create(:typo, sample: sample, name: "Late Bronze Age",
                              approx_start_time: -1100, approx_end_time: -800)

    other.update!(name: "Roman Iron Age", approx_start_time: -550, approx_end_time: -350)

    assert_predicate other, :superseded?
    assert_equal canonical.id, other.merged_into_id
  end

  test "does not auto-merge when name is unique" do
    sample = create(:sample)
    create(:typo, sample: sample, name: "Roman Iron Age")
    other = create(:typo, sample: sample, name: "Late Bronze Age")

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test "does not auto-merge when name matches but approx_start_time differs" do
    sample = create(:sample)
    create(:typo, sample: sample, name: "Roman Iron Age",
                       approx_start_time: -550, approx_end_time: -350)
    other = create(:typo, sample: sample, name: "Roman Iron Age",
                              approx_start_time: -500, approx_end_time: -350)

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test "does not auto-merge when name matches but sample differs" do
    sample_a = create(:sample)
    sample_b = create(:sample)
    create(:typo, sample: sample_a, name: "Roman Iron Age",
                       approx_start_time: -550, approx_end_time: -350)
    other = create(:typo, sample: sample_b, name: "Roman Iron Age",
                              approx_start_time: -550, approx_end_time: -350)

    # Cross-sample matches are excluded by the key
    assert_not other.superseded?
    assert_nil other.merged_into_id
    assert_predicate Typo.find(other.id), :persisted?
  end

  test "auto-merges when key attrs match with nil on both sides (nil_matches_nil)" do
    sample = create(:sample)
    canonical = create(:typo, sample: sample, name: "Undated unit",
                                  approx_start_time: nil, approx_end_time: nil)
    dupe = create(:typo, sample: sample, name: "Undated unit",
                              approx_start_time: nil, approx_end_time: nil)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test "does not auto-merge when approx_start_time is set on one side and nil on the other" do
    sample = create(:sample)
    create(:typo, sample: sample, name: "Roman Iron Age",
                       approx_start_time: -550, approx_end_time: -350)
    other = create(:typo, sample: sample, name: "Roman Iron Age",
                              approx_start_time: nil, approx_end_time: -350)

    # approx_start_time has :nil_matches_nil, so nil==nil matches, but nil != -550
    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test "reassigns non-colliding citations to the canonical on create" do
    sample = create(:sample)
    canonical = create(:typo, sample: sample, name: "Roman Iron Age",
                                  approx_start_time: -550, approx_end_time: -350)
    reference = create(:reference)

    dupe = build(:typo, sample: sample, name: "Roman Iron Age",
                            approx_start_time: -550, approx_end_time: -350)
    dupe.citations << build(:citation, reference: reference, citing: dupe)
    dupe.save!

    assert_predicate dupe, :superseded?
    assert_equal 0, Citation.where(citing_type: "Typo", citing_id: dupe.id).count
    assert_equal 1, Citation.where(citing_type: "Typo", citing_id: canonical.id, reference: reference).count
  end

  test "destroys colliding citations on create" do
    sample = create(:sample)
    canonical = create(:typo, sample: sample, name: "Roman Iron Age",
                                  approx_start_time: -550, approx_end_time: -350)
    reference = create(:reference)
    create(:citation, reference: reference, citing: canonical)

    dupe = build(:typo, sample: sample, name: "Roman Iron Age",
                            approx_start_time: -550, approx_end_time: -350)
    dupe.citations << build(:citation, reference: reference, citing: dupe)
    dupe.save!

    assert_predicate dupe, :superseded?
    # Canonical's citation remains; dupe's collision is destroyed
    assert_equal 1, Citation.where(citing_type: "Typo", citing_id: canonical.id, reference: reference).count
    assert_equal 0, Citation.where(citing_type: "Typo", citing_id: dupe.id).count
  end
end
