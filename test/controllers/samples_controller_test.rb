# frozen_string_literal: true

require 'test_helper'

class SamplesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # SamplesController is JSON/CSV only; HTML is 406 (not_acceptable).
  # `#show` declares `format.json` in its respond_to; `#index`
  # declares only `format.json` and `format.csv`.
  smoke_tests(
    actions: %i[index show],
    param_key: :sample,
    statuses: {
      index: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      show: { not_signed_in: :not_acceptable, signed_in: :not_acceptable }
    }
  )
end
