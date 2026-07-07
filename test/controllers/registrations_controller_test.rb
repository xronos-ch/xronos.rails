# frozen_string_literal: true

require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # Devise registrations are not standard REST resources; this is a
  # focused wiring test for the registration actions.
  #
  # Note: the custom RegistrationsController#create override
  # (app/controllers/registrations_controller.rb:3-6) intentionally
  # ignores the save result and re-renders the :new template. The
  # smoke test pins this behaviour.

  test 'new returns the sign-up form' do
    get new_user_registration_path
    assert_response :success
  end

  test 'create re-renders the sign-up form regardless of save result' do
    password = 'password'
    post user_registration_path, params: {
      user: {
        email: "new-#{SecureRandom.hex(8)}@xronos.test",
        password: password,
        password_confirmation: password
      }
    }

    # The controller always renders :new (see RegistrationsController#create).
    assert_response :success
  end
end
