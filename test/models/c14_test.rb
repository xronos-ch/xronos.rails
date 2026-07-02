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
#  superseded_by  :integer
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
#  index_c14s_on_superseded_by   (superseded_by)
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
end
