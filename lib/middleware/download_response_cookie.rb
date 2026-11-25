# frozen_string_literal: true

require 'rack'

module Xronos
  module Middleware
    # Adds a short-lived status cookie to correlated download responses.
    class DownloadResponseCookie
      REQUEST_ID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
      COOKIE_PREFIX = 'xronos_download_'
      COOKIE_MAX_AGE = 60

      def initialize(app)
        @app = app
      end

      def call(env)
        request_id = download_request_id(env)
        status, headers, body = @app.call(env)
        return [status, headers, body] unless request_id&.match?(REQUEST_ID_PATTERN)

        [status, response_headers(headers, env, request_id, status), body]
      end

      private

      def download_request_id(env)
        query_string = env['QUERY_STRING'].to_s
        return unless query_string.include?('download_request_id=')

        Rack::Utils.parse_query(query_string)['download_request_id'].to_s
      end

      def response_headers(headers, env, request_id, status)
        headers = headers.dup
        Rack::Utils.set_cookie_header!(headers, "#{COOKIE_PREFIX}#{request_id}", cookie_attributes(env, status))
        headers
      end

      def cookie_attributes(env, status)
        {
          value: status.between?(200, 299) ? 'ready' : "error-#{status}",
          max_age: COOKIE_MAX_AGE,
          path: '/',
          same_site: :lax,
          secure: env['rack.url_scheme'] == 'https'
        }
      end
    end
  end
end
