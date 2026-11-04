# frozen_string_literal: true

require 'test_helper'

class Issues::ReferencesControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    requires_admin: false,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success }
    }
  )

  test 'long_label issue page renders' do
    sign_in create(:user)
    create(:reference, short_ref: 'An extremely long reference label exceeding thirty characters')

    get '/issues/references/long_label'

    assert_response :success
    assert_includes response.body, 'An extremely long reference label exceeding thirty characters'
  end
end
