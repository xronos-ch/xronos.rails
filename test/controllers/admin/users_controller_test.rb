# frozen_string_literal: true

require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest # rubocop:disable Style/ClassAndModuleChildren
  include ControllerSmokeTest
  include Devise::Test::IntegrationHelpers

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

  test 'signed-in non-admin users cannot access admin users index' do
    sign_in create(:user, email: "non-admin-index-#{SecureRandom.hex(8)}@xronos.test"), scope: :user

    get admin_users_path

    assert_not_includes [200, 201, 204], response.status
  end

  test 'signed-in non-admin users cannot create admin users' do
    sign_in create(:user, email: "non-admin-create-#{SecureRandom.hex(8)}@xronos.test"), scope: :user

    assert_no_difference('User.count') do
      post admin_users_path, params: {
        user: {
          email: "unauthorized-create-#{SecureRandom.hex(8)}@xronos.test",
          password: 'password',
          password_confirmation: 'password'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end

  test 'admin users can access admin users index' do
    sign_in create(:user, admin: true, email: "admin-index-#{SecureRandom.hex(8)}@xronos.test"), scope: :user

    get admin_users_path

    assert_response :success
  end
end