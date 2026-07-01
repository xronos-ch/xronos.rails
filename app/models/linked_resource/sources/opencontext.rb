# frozen_string_literal: true

# Attributes for the OpenContext source. Autoloaded by Zeitwerk from the
# filename via the convention app/models/linked_resource/sources/<key>.rb
# → LinkedResource::Sources::<KeyCamelized>. When this module is loaded,
# the file registers itself with the Source registry; the LinkedResource
# model only triggers the load (via KNOWN_SOURCES) and then asserts the
# registration happened.
#
# OpenContext ids are standard UUIDs (RFC 4122) — see
# LinkedResource::Source::UUID_PATTERN for the shared pattern. The same
# URL construct works for both site subjects (e.g.
# https://opencontext.org/subjects/8606d40b-...) and individual record
# subjects (e.g. C14s), so the source is host-agnostic; each host model
# that wants to link to OpenContext declares `linkable_to :opencontext`
# separately.
class LinkedResource
  module Sources
    module Opencontext
      ATTRIBUTES = {
        name: "OpenContext",
        url_template: "https://opencontext.org/subjects/%<id>s",
        id_pattern: LinkedResource::Source::UUID_PATTERN,
        description: "OpenContext record"
      }.freeze

      LinkedResource::Source.register(:opencontext, **ATTRIBUTES)
    end
  end
end
