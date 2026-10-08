# frozen_string_literal: true

require 'test_helper'

class LabIdTest < ActiveSupport::TestCase
  test 'does not match identifiers without separators' do
    lab_id = LabId.new('BK88061')
    assert_not lab_id.valid?
    assert_equal 'BK88061', lab_id.to_s
    assert_nil lab_id.lab_code
    assert_nil lab_id.lab_number
  end

  test 'matches identifiers with standard hyphen separator' do
    lab_id = LabId.new('OxA-12345')
    assert lab_id.valid?
    assert_equal 'OxA', lab_id.lab_code
    assert_equal '12345', lab_id.lab_number
    assert_equal 'OxA-12345', lab_id.to_s
  end

  test 'matches identifiers with Beta prefix' do
    lab_id = LabId.new('Beta-367941')
    assert lab_id.valid?
    assert_equal 'Beta', lab_id.lab_code
    assert_equal '367941', lab_id.lab_number
    assert_equal 'Beta-367941', lab_id.to_s
  end

  test 'matches identifiers with underscore separator' do
    lab_id = LabId.new('LAB_123')
    assert lab_id.valid?
    assert_equal 'LAB', lab_id.lab_code
    assert_equal '123', lab_id.lab_number
  end

  test 'matches identifiers with dot separator' do
    lab_id = LabId.new('LAB.123')
    assert lab_id.valid?
    assert_equal 'LAB', lab_id.lab_code
    assert_equal '123', lab_id.lab_number
  end

  test 'matches identifiers with Unicode hyphen separators' do
    # U+2010 HYPHEN
    lab_id = LabId.new("OxA\u201012345")
    assert lab_id.valid?
    assert_equal 'OxA', lab_id.lab_code
    assert_equal '12345', lab_id.lab_number

    # U+2013 EN DASH
    lab_id = LabId.new("OxA\u201312345")
    assert lab_id.valid?
    assert_equal 'OxA', lab_id.lab_code
    assert_equal '12345', lab_id.lab_number
  end

  test 'matches identifiers with trailing letter suffix' do
    lab_id = LabId.new('OxA-12345A')
    assert lab_id.valid?
    assert_equal 'OxA', lab_id.lab_code
    assert_equal '12345A', lab_id.lab_number
  end

  test 'invalid? returns true when not valid' do
    lab_id = LabId.new('BK88061')
    assert lab_id.invalid?
  end

  test 'invalid? returns false when valid' do
    lab_id = LabId.new('OxA-12345')
    assert_not lab_id.invalid?
  end
end
