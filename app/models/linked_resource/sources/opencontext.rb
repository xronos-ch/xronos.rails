# frozen_string_literal: true

# Host-agnostic: same URL works for both Site and C14 subjects, so each
# host model declares `linkable_to :opencontext` separately.
class LinkedResource
  module Sources
    module Opencontext
      ATTRIBUTES = {
        name: "OpenContext",
        url_template: "https://opencontext.org/subjects/%<id>s",
        id_pattern: LinkedResource::Source::UUID_PATTERN,
        icon: "opencontext",
        description: "OpenContext record"
      }.freeze

      LinkedResource::Source.register(:opencontext, **ATTRIBUTES)
    end
  end
end
