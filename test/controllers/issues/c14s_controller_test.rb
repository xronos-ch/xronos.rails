# frozen_string_literal: true

require 'test_helper'

class Issues::C14sControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    requires_admin: false,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success }
    }
  )

  test 'lists active measurements with matching lab identifier, age and error' do
    sign_in create(:user)
    attributes = { lab_identifier: 'K-42', bp: 3400, std: 45 }
    first = create(:c14, **attributes, method: 'AMS')
    second = create(:c14, **attributes, method: 'conventional')
    other_age = create(:c14, **attributes.merge(bp: 3410))
    other_error = create(:c14, **attributes.merge(std: 46))
    superseded = create(:c14, :superseded_by, **attributes, canonical: first)

    get "#{issues_c14s_path}/potential_duplicate"

    assert_response :success
    assert_dom "tbody tr", count: 2
    assert_dom "tbody tr:has(a[href='#{c14_path(first)}']) a[href='#{c14_path(second)}']"
    assert_dom "tbody a[href='#{c14_path(other_age)}']", count: 0
    assert_dom "tbody a[href='#{c14_path(other_error)}']", count: 0
    assert_dom "tbody a[href='#{c14_path(superseded)}']", count: 0
    assert first.potential_duplicate?
    assert_not other_age.potential_duplicate?
  end
end
