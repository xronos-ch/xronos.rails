# frozen_string_literal: true

require 'test_helper'

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  # Devise sessions are not standard REST resources; this is a focused
  # wiring test for the three session actions.

  Rails.application.routes.eager_load!
  include Devise::Test::IntegrationHelpers

  test 'new returns the sign-in form' do
    get new_user_session_path
    assert_response :success
  end

  test 'create with valid credentials signs the user in' do
    user = create(:user, password: 'password', password_confirmation: 'password')

    post user_session_path, params: { user: { email: user.email, password: 'password' } }

    assert_response :redirect
  end

  test 'create with invalid credentials re-renders the form' do
    post user_session_path, params: { user: { email: 'nobody@example.test', password: 'wrong' } }

    # Devise re-renders :new (200) on authentication failure, not 422.
    assert_response :success
  end

  test 'destroy signs the user out with a 303 see_other' do
    user = create(:user)
    sign_in user

    delete destroy_user_session_path

    assert_response :see_other
  end
end
