# frozen_string_literal: true

module Xronos
  # Avoid persisting an empty session record when the store first loads it.
  class ActiveRecordSession < ActiveRecord::SessionStore::Session
    def save(...)
      return true if new_record? && data.empty?

      super
    end
  end
end
