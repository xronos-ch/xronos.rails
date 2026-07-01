# frozen_string_literal: true

class LinkedResource
  module Sources
    module Pleiades
      ATTRIBUTES = {
        name: "Pleiades",
        url_template: "https://pleiades.stoa.org/places/%<id>s",
        id_pattern: /\A\d+\z/,
        description: "Pleiades place resource"
      }.freeze

      LinkedResource::Source.register(:pleiades, **ATTRIBUTES)
    end
  end
end
