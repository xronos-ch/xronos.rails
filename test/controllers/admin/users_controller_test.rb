# frozen_string_literal: true

require 'test_helper'

Rails.application.routes.eager_load!

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'signed-in non-admin users cannot access admin users index' do
    sign_in create(:user)

    get admin_users_path

    assert_not_includes [200, 201, 204], response.status
  end

  test 'signed-in non-admin users cannot create admin users' do
    sign_in create(:user)

    assert_no_difference('User.count') do
      post admin_users_path, params: {
        user: {
          email: 'unauthorized-create@example.test',
          password: 'password',
          password_confirmation: 'password'
        }
      }
    end

    assert_not_includes [200, 201, 204], response.status
  end

  test 'admin users can access admin users index' do
    sign_in create(:user, admin: true), scope: :user

    get admin_users_path

    assert_response :success
  end
end