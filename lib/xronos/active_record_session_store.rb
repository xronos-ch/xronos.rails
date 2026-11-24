# frozen_string_literal: true

module Xronos
  # Defers creating session records until the Rack session is written.
  class ActiveRecordSessionStore < ActionDispatch::Session::ActiveRecordStore
    private

    def get_session_model(request, id)
      logger.silence do
        model = cached_session_model(request, id) || get_session_with_fallback(id)

        unless model
          id = generate_sid
          model = session_class.new(session_id: id.private_id, data: {})
        end

        cache_session_model(request, model)
        [model, id]
      end
    end

    def cached_session_model(request, id)
      model = request.env[SESSION_RECORD_KEY]
      model if id && model&.session_id == id.private_id
    end

    def cache_session_model(request, model)
      if request.env[ENV_SESSION_OPTIONS_KEY][:id].nil?
        request.env[SESSION_RECORD_KEY] = model
      else
        request.env[SESSION_RECORD_KEY] ||= model
      end
    end
  end
end
