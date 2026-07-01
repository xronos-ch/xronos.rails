# frozen_string_literal: true

class LinkedResource
  module Sources
    module Vici
      ATTRIBUTES = {
        name: "Vici.org",
        url_template: "https://vici.org/vici/%<id>s/",
        id_pattern: /\A\d+\z/,
        description: "Vici.org place resource"
      }.freeze

      LinkedResource::Source.register(:vici, **ATTRIBUTES)
    end
  end
end
