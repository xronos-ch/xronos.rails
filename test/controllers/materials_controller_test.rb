# frozen_string_literal: true

require 'test_helper'

class MaterialsControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # NOTE: This controller's respond_to blocks do not declare HTML on
  # index/show/new, so the default-HTML smoke test surfaces a 406
  # (not_acceptable) for those actions — there is no standalone HTML
  # view for materials. create has a format.html redirect, so it
  # returns 302 (found) for signed-in users. edit/update/destroy are
  # CanCan-denied (404).
  smoke_tests(
    param_key: :material,
    statuses: {
      index: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      show: { not_signed_in: :not_acceptable, signed_in: :not_acceptable },
      new: { not_signed_in: :not_found, signed_in: :not_acceptable },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )
end
