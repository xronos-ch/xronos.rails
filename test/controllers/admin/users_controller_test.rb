# frozen_string_literal: true

require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest

  # NOTE: this controller is missing load_and_authorize_resource.
  # The strict admin gating test (test_*_rejects_signed_in_non_admin)
  # will surface this as a failing test if a non-admin user is allowed
  # to reach the mutating actions.
  smoke_tests(
    actions: %i[index new create edit update destroy],
    param_key: :user,
    requires_admin: true,
    statuses: {
      index: { not_signed_in: :redirect, signed_in: :success },
      new: { not_signed_in: :redirect, signed_in: :success },
      create: { not_signed_in: :redirect, signed_in: :see_other },
      edit: { not_signed_in: :redirect, signed_in: :success },
      update: { not_signed_in: :redirect, signed_in: :see_other },
      destroy: { not_signed_in: :redirect, signed_in: :see_other }
    }
  )

  # Admin::UsersController#create expects email, password,
  # password_confirmation. attributes_for(:user) returns those plus
  # the passphrase (set via attr_accessor on User).
  def smoke_payload_for(_action)
    password = SecureRandom.hex(16)
    {
      email: "smoke-#{SecureRandom.hex(8)}@xronos.test",
      password: password,
      password_confirmation: password,
      admin: false
    }
  end
end
