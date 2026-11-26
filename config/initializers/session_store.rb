# frozen_string_literal: true

require 'active_record/session_store'
require_relative '../../lib/xronos/active_record_session'

ActionDispatch::Session::ActiveRecordStore.session_class = Xronos::ActiveRecordSession
Rails.application.config.session_store :active_record_store, key: '_my_app_session'
