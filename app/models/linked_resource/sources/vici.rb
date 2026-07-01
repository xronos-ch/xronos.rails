# frozen_string_literal: true

# Attributes for the Vici.org source. Autoloaded by Zeitwerk from the
# filename via the convention app/models/linked_resource/sources/<key>.rb
# → LinkedResource::Sources::<KeyCamelized>. When this module is loaded,
# the file registers itself with the Source registry; the LinkedResource
# model only triggers the load (via KNOWN_SOURCES) and then asserts the
# registration happened.
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
