# frozen_string_literal: true

class LinkedResource
  module Sources
    module IdaiGazetteer
      ATTRIBUTES = {
        name: "iDAI.gazetteer",
        url_template: "https://gazetteer.dainst.org/place/%<id>s",
        id_pattern: /\A\d+\z/,
        icon: "dai",
        description: "iDAI.gazetteer place resource"
      }.freeze

      LinkedResource::Source.register(:idai_gazetteer, **ATTRIBUTES)
    end
  end
end
