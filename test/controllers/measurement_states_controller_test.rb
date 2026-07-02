# frozen_string_literal: true

require 'test_helper'

class MeasurementStatesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # All actions are JSON-only; HTML is not handled by the controller's
  # respond_to block. The default smoke payload (FactoryBot.attributes_for)
  # satisfies the strong params (:name, :description).
  #
  # Note: this controller is missing load_and_authorize_resource. The
  # not_signed_in status for mutating actions is expected to be in
  # REJECTED_STATUSES (302/303/404/422); if the test fails, that's a
  # surfacing of the auth-bypass finding.
  smoke_tests(
    param_key: :measurement_state,
    query_params: { format: :json },
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :success, signed_in: :success },
      new: { not_signed_in: :no_content, signed_in: :no_content },
      create: { not_signed_in: :redirect, signed_in: :created },
      edit: { not_signed_in: :no_content, signed_in: :no_content },
      update: { not_signed_in: :redirect, signed_in: :ok },
      destroy: { not_signed_in: :redirect, signed_in: :no_content }
    }
  )
end
