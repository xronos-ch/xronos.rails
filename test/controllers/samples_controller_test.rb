# frozen_string_literal: true

require 'test_helper'

class SamplesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # SamplesController is JSON/CSV only; HTML is 406.
  smoke_tests(
    actions: %i[index show],
    param_key: :sample,
    query_params: { format: :json },
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :success, signed_in: :success }
    }
  )
end
