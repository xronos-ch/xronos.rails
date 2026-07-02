# frozen_string_literal: true

require 'test_helper'

class SiteTypesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # NOTE: This controller's #index has a respond_to block that only
  # handles :csv. The strict smoke test surfaces the resulting 406
  # responses for HTML/JSON as a controller-completeness finding.
  # For mutating actions against a member, CanCan denies non-admin
  # access (404). For :create, the format check runs after CanCan
  # allows it, so the response is 406 instead.
  smoke_tests(
    param_key: :site_type,
    query_params: { format: :csv },
    statuses: {
      index: { not_signed_in: :success, signed_in: :success },
      show: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      new: { not_signed_in: :not_found, signed_in: :not_acceptable },
      create: { not_signed_in: :not_found, signed_in: :not_acceptable },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )
end
