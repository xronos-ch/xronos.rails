# config/initializers/client_ip.rb

require "ipaddr"

module ClientIp
  module_function

  def from_rack_request(req)
    cf_ip = req.get_header("HTTP_CF_CONNECTING_IP").presence

    if valid_ip?(cf_ip)
      cf_ip
    else
      req.ip
    end
  end

  def valid_ip?(value)
    return false if value.blank?

    IPAddr.new(value)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end