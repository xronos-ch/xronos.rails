# frozen_string_literal: true

require 'test_helper'

class Issues::TaxonsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    requires_admin: false,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success }
    }
  )
end
