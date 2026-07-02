# frozen_string_literal: true

require 'test_helper'

class UserProfilesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  # attributes_for(:user_profile) returns {user: <User>, ...}; the
  # controller's strong params permit :user_id.
  smoke_tests(
    actions: %i[new create edit update destroy],
    param_key: :user_profile,
    statuses: {
      new: { not_signed_in: :not_found, signed_in: :success },
      create: { not_signed_in: :not_found, signed_in: :found },
      edit: { not_signed_in: :not_found, signed_in: :not_found },
      update: { not_signed_in: :not_found, signed_in: :not_found },
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )

  def smoke_payload_for(_action)
    attributes_for(:user_profile).except(:user).merge(user_id: create(:user).id)
  end
end
