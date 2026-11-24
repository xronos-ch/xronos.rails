# frozen_string_literal: true

require 'action_dispatch/session/active_record_store'
require_relative '../../lib/xronos/active_record_session_store'

Rails.application.config.session_store Xronos::ActiveRecordSessionStore, key: '_my_app_session'
