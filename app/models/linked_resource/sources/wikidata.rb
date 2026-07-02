# frozen_string_literal: true

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
