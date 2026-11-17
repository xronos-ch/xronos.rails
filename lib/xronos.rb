# frozen_string_literal: true

##
# Xronos
#
# Project-wide constants for the XRONOS application. Lib clients and
# concerns that make outbound HTTP requests should use Xronos::USER_AGENT
# and Xronos::CONTACT_EMAIL so we identify ourselves consistently.
#
# This module is co-located with the existing Xronos::ImportRunner and
# Xronos::DestroyTree classes under lib/xronos/.
module Xronos
  # The User-Agent string sent by every HTTP request made on behalf of
  # the XRONOS project. Service-name + project URL is the standard
  # format recommended by RFC 7231 and by the upstream APIs we call.
  USER_AGENT = "XRONOS <https://xronos.ch>".freeze

  # Project contact email. Used as the `From` header per the GBIF API
  # convention; available for any service that wants to identify the
  # operator behind the request.
  CONTACT_EMAIL = "admin@xronos.ch".freeze
end
