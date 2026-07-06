# frozen_string_literal: true

require 'test_helper'

class UserProfiles::PhotoControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[destroy],
    param_key: :user_profile,
    parent: { user_profile_id: :user_profile },
    singular_resource: true,
    statuses: {
      # The smoke test creates a UserProfile for a different user than
      # the signed-in smoke user, so :edit is denied by CanCan. To test
      # the success path, override smoke_record/smoke_parent to return a
      # profile owned by the signed-in user.
      destroy: { not_signed_in: :not_found, signed_in: :not_found }
    }
  )
end
