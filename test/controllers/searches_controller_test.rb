# frozen_string_literal: true

require 'test_helper'

class SearchesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    statuses: {
      index: { not_signed_in: :success, signed_in: :success }
    }
  )
end
