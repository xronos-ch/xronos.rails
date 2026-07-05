# frozen_string_literal: true

# == Schema Information
#
# Table name: c14s
# Database name: primary
#
#  id             :bigint           not null, primary key
#  bp             :integer
#  cal_bp         :integer
#  cal_std        :integer
#  delta_15n      :float
#  delta_c13      :float
#  delta_c13_std  :float
#  lab_identifier :string
#  method         :string
#  std            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  c14_lab_id     :bigint
#  sample_id      :bigint
#
# Indexes
#
#  index_c14s_on_c14_lab_id      (c14_lab_id)
#  index_c14s_on_lab_identifier  (lab_identifier)
#  index_c14s_on_method          (method)
#  index_c14s_on_sample_id       (sample_id)
#
require 'test_helper'

class C14Test < ActiveSupport::TestCase
  test 'destroying a c14 destroys its citations' do
    c14 = create(:c14, :with_citations, citations_count: 2)
    assert_dependent_destroy(c14, :citations, count: 2)
  end

  test 'calculates f14c from conventional radiocarbon age' do
    c14 = C14.new(bp: 4500)

    assert_in_delta Math.exp(-4500.0 / C14::LIBBY_MEAN_LIFE),
                    c14.f14c,
                    0.0000001
  end

  test 'calculates f14c error from conventional radiocarbon age and error' do
    c14 = C14.new(bp: 4500, std: 30)

    expected_f14c = Math.exp(-4500.0 / C14::LIBBY_MEAN_LIFE)
    expected_error = expected_f14c * 30.0 / C14::LIBBY_MEAN_LIFE

    assert_in_delta expected_error,
                    c14.f14c_error,
                    0.0000001
  end

  test 'returns nil f14c without conventional radiocarbon age' do
    c14 = C14.new(bp: nil)

    assert_nil c14.f14c
  end

  test 'returns nil f14c error without conventional radiocarbon age or error' do
    assert_nil C14.new(bp: nil, std: 30).f14c_error
    assert_nil C14.new(bp: 4500, std: nil).f14c_error
  end

  #
  # Deduplication
  #

  test 'auto-merges on create when all key attrs match' do
    sample = create(:sample)
    canonical = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                                  bp: 3500, std: 30, method: "AMS",
                                  delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    dupe = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                            bp: 3500, std: 30, method: "AMS",
                            delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'auto-merges on update when an update creates a duplicate' do
    sample = create(:sample)
    canonical = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                                  bp: 3500, std: 30, method: "AMS",
                                  delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    other = create(:c14, lab_identifier: "OxA-67890", sample: sample,
                              bp: 4000, std: 35, method: "AMS",
                              delta_15n: -22.0, delta_c13: -18.0, delta_c13_std: 1.2)

    other.update!(lab_identifier: "OxA-12345", bp: 3500, std: 30,
                  delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)

    assert_predicate other, :superseded?
    assert_equal canonical.id, other.merged_into_id
  end

  test 'does not auto-merge when lab_identifier is unique' do
    sample = create(:sample)
    create(:c14, lab_identifier: "OxA-12345", sample: sample)
    other = create(:c14, lab_identifier: "OxA-67890", sample: sample)

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when lab_identifier matches but bp differs' do
    sample = create(:sample)
    create(:c14, lab_identifier: "OxA-12345", sample: sample, bp: 3500, std: 30)
    other = create(:c14, lab_identifier: "OxA-12345", sample: sample, bp: 4000, std: 30)

    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'does not auto-merge when lab_identifier matches but sample differs' do
    sample_a = create(:sample)
    sample_b = create(:sample)
    create(:c14, lab_identifier: "OxA-12345", sample: sample_a, bp: 3500, std: 30)
    other = create(:c14, lab_identifier: "OxA-12345", sample: sample_b, bp: 3500, std: 30)

    # Cross-sample matches are excluded by the key
    assert_not other.superseded?
    assert_nil other.merged_into_id
    assert_predicate C14.find(other.id), :persisted?
  end

  test 'auto-merges when key attrs match with nil on both sides (nil_matches_nil)' do
    sample = create(:sample)
    canonical = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                                  bp: 3500, std: 30, method: nil,
                                  delta_15n: nil, delta_c13: nil, delta_c13_std: nil)
    dupe = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                            bp: 3500, std: 30, method: nil,
                            delta_15n: nil, delta_c13: nil, delta_c13_std: nil)

    assert_predicate dupe, :superseded?
    assert_equal canonical.id, dupe.merged_into_id
  end

  test 'does not auto-merge when method is set on one side and nil on the other' do
    sample = create(:sample)
    create(:c14, lab_identifier: "OxA-12345", sample: sample, bp: 3500, std: 30, method: "AMS")
    other = create(:c14, lab_identifier: "OxA-12345", sample: sample, bp: 3500, std: 30, method: nil)

    # method has :nil_matches_nil, so nil==nil matches, but nil != "AMS"
    assert_not other.superseded?
    assert_nil other.merged_into_id
  end

  test 'reassigns non-colliding citations to the canonical on create' do
    sample = create(:sample)
    canonical = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                                  bp: 3500, std: 30, method: "AMS",
                                  delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    reference = create(:reference)

    dupe = build(:c14, lab_identifier: "OxA-12345", sample: sample,
                            bp: 3500, std: 30, method: "AMS",
                            delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    dupe.citations << build(:citation, reference: reference, citing: dupe)
    dupe.save!

    assert_predicate dupe, :superseded?
    assert_equal 0, Citation.where(citing_type: "C14", citing_id: dupe.id).count
    assert_equal 1, Citation.where(citing_type: "C14", citing_id: canonical.id, reference: reference).count
  end

  test 'destroys colliding citations on create' do
    sample = create(:sample)
    canonical = create(:c14, lab_identifier: "OxA-12345", sample: sample,
                                  bp: 3500, std: 30, method: "AMS",
                                  delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    reference = create(:reference)
    create(:citation, reference: reference, citing: canonical)

    dupe = build(:c14, lab_identifier: "OxA-12345", sample: sample,
                            bp: 3500, std: 30, method: "AMS",
                            delta_15n: -25.0, delta_c13: -20.0, delta_c13_std: 1.5)
    dupe.citations << build(:citation, reference: reference, citing: dupe)
    dupe.save!

    assert_predicate dupe, :superseded?
    # Canonical's citation remains; dupe's collision is destroyed
    assert_equal 1, Citation.where(citing_type: "C14", citing_id: canonical.id, reference: reference).count
    assert_equal 0, Citation.where(citing_type: "C14", citing_id: dupe.id).count
  end
end
