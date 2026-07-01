# frozen_string_literal: true

# Attributes for the Wikidata source. Autoloaded by Zeitwerk from the
# filename via the convention app/models/linked_resource/sources/<key>.rb
# → LinkedResource::Sources::<KeyCamelized>. When this module is loaded,
# the file registers itself with the Source registry; the LinkedResource
# model only triggers the load (via KNOWN_SOURCES) and then asserts the
# registration happened.
class LinkedResource
  module Sources
    module Wikidata
      ATTRIBUTES = {
        name: "Wikidata",
        url_template: "https://www.wikidata.org/wiki/%<id>s",
        id_pattern: /\AQ\d+\z/,
        icon: "wikidata",
        description: "Wikidata item corresponding to this record"
      }.freeze

      LinkedResource::Source.register(:wikidata, **ATTRIBUTES)
    end
  end
end
