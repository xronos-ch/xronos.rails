# frozen_string_literal: true

require 'test_helper'

class ReferencesControllerTest < ActionDispatch::IntegrationTest
  test 'show redirects to the canonical record when the reference is superseded' do
    canonical = create(:reference)
    superseded = create(:reference, :superseded, superseded_by_reference: canonical)

    get reference_path(superseded)

    assert_response :moved_permanently
    assert_equal reference_url(canonical), response.location
  end

  test 'show follows a multi-link superseded chain to the canonical' do
    canonical = create(:reference)
    middle = create(:reference, :superseded, superseded_by_reference: canonical)
    leaf = create(:reference, :superseded, superseded_by_reference: middle)

    get reference_path(leaf)

    assert_response :moved_permanently
    assert_equal reference_url(canonical), response.location
  end
end
