# frozen_string_literal: true

require 'test_helper'

class ReferencesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    param_key: :reference,
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :success,  signed_in: :success },
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  test 'show redirects to the canonical record when the reference is superseded' do
    canonical = create(:reference)
    superseded = create(:reference, :superseded_by, canonical: canonical)

    get reference_path(superseded)

    assert_response :moved_permanently
    assert_equal reference_url(canonical), response.location
  end

  test 'show follows a re-pointed chain to the canonical' do
    canonical = create(:reference)
    middle = create(:reference)
    leaf = create(:reference)

    leaf.supersede!(middle)
    middle.supersede!(canonical)

    get reference_path(leaf)

    assert_response :moved_permanently
    assert_equal reference_url(canonical), response.location
  end
end
