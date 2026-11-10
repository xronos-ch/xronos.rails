# frozen_string_literal: true

require 'test_helper'

module Sessions
  class TrimJobTest < ActiveJob::TestCase
    setup do
      @sessions = ActiveRecord::SessionStore::Session
      @previous_threshold = ENV.delete('SESSION_DAYS_TRIM_THRESHOLD')
    end

    teardown do
      ENV['SESSION_DAYS_TRIM_THRESHOLD'] = @previous_threshold
    end

    test 'deletes stale sessions and keeps sessions at or after the cutoff' do
      travel_to Time.utc(2026, 11, 10, 12) do
        stale = create_session(8.days.ago)
        boundary = create_session(7.days.ago)
        recent = create_session(1.day.ago)

        assert_equal 1, TrimJob.perform_now

        assert_not @sessions.exists?(stale.id)
        assert @sessions.exists?(boundary.id)
        assert @sessions.exists?(recent.id)
      end
    end

    test 'honors the configured retention and caps a run at the oldest batch' do
      ENV['SESSION_DAYS_TRIM_THRESHOLD'] = '14'

      travel_to Time.utc(2026, 11, 10, 12) do
        sessions = @sessions.insert_all!(
          Array.new(5_000) do
            { session_id: SecureRandom.hex(16), created_at: 21.days.ago, updated_at: 21.days.ago }
          end,
          returning: %w[id]
        )
        next_oldest = create_session(15.days.ago)
        within_retention = create_session(8.days.ago)

        assert_equal 5_000, TrimJob.perform_now

        assert_not @sessions.exists?(id: sessions.rows.flatten)
        assert @sessions.exists?(next_oldest.id)
        assert @sessions.exists?(within_retention.id)
      end
    end

    test 'rejects a retention threshold of zero before deleting anything' do
      ENV['SESSION_DAYS_TRIM_THRESHOLD'] = '0'
      session = create_session(1.day.ago)

      assert_raises(ArgumentError) { TrimJob.perform_now }
      assert @sessions.exists?(session.id)
    end

    private

    def create_session(updated_at)
      @sessions.create!(session_id: SecureRandom.hex(16), data: {}, updated_at: updated_at)
    end
  end
end
