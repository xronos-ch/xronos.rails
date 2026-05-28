class Rack::Attack
  if Rails.env.development?
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  else
    Rack::Attack.cache.store = Rails.cache
  end

  Rack::Attack.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}

    Rails.logger.warn(
      "Rate limit exceeded: " \
        "name=#{request.env['rack.attack.matched']} " \
        "ip=#{ClientIp.from_rack_request(request)} " \
        "path=#{request.path} " \
        "limit=#{match_data[:limit]} " \
        "period=#{match_data[:period]}"
    )

    [
      429,
      {
        "Content-Type" => "text/plain",
        "Retry-After" => match_data[:period].to_s
      },
      ["Too many requests\n"]
    ]
  end

  throttle("requests/ip", limit: 120, period: 1.minute) do |req|
    ClientIp.from_rack_request(req)
  end

  throttle("csv/ip", limit: 5, period: 1.minute) do |req|
    ClientIp.from_rack_request(req) if req.path.end_with?(".csv")
  end

  throttle("data/ip", limit: 60, period: 1.minute) do |req|
    ClientIp.from_rack_request(req) if req.path.start_with?("/data")
  end

  throttle("deep-pagination/ip", limit: 20, period: 1.minute) do |req|
    page = req.params["page"].to_i

    ClientIp.from_rack_request(req) if page > 100
  end
end