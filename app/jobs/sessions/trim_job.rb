# frozen_string_literal: true

module Sessions
  # Deletes one bounded batch of inactive sessions in each scheduled run.
  class TrimJob < ApplicationJob
    BATCH_SIZE = 5_000

    queue_as :default
    limits_concurrency key: 'trim_sessions', duration: 10.minutes, on_conflict: :discard

    def perform
      cutoff = retention_days.days.ago
      deleted = ActiveRecord::SessionStore::Session.with_connection do |connection|
        delete_batch(connection, cutoff)
      end

      Rails.logger.info { "Deleted #{deleted} inactive sessions" }
      deleted
    end

    private

    def retention_days
      days = Integer(ENV.fetch('SESSION_DAYS_TRIM_THRESHOLD', '7'), 10, exception: false)
      raise ArgumentError, 'SESSION_DAYS_TRIM_THRESHOLD must be a positive integer' unless days&.positive?

      days
    end

    def delete_batch(connection, cutoff) # rubocop:disable Metrics/MethodLength
      table = connection.quote_table_name(ActiveRecord::SessionStore::Session.table_name)
      connection.transaction do
        connection.execute('SET LOCAL lock_timeout = 1000')
        connection.execute('SET LOCAL statement_timeout = 15000')
        connection.delete(<<~SQL)
          WITH batch AS (
            SELECT id FROM #{table}
            WHERE updated_at < #{connection.quote(cutoff)}
            ORDER BY updated_at
            LIMIT #{BATCH_SIZE}
            FOR UPDATE SKIP LOCKED
          )
          DELETE FROM #{table} AS sessions
          USING batch
          WHERE sessions.id = batch.id
        SQL
      end
    end
  end
end
