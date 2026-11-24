# frozen_string_literal: true

require 'test_helper'

class EntryPagesTest < ActionDispatch::IntegrationTest
  test 'root page responds successfully' do
    get root_path

    assert_response :success
  end

  test 'anonymous public requests do not create database sessions' do
    session_store = ActiveRecord::SessionStore::Session

    assert_no_difference -> { session_store.count } do
      get root_path
      assert_response :success
      assert_nil cookies['_my_app_session']

      get '/data'
      assert_response :success
    end
  end
end
