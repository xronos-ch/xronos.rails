# frozen_string_literal: true

# Register known linked resource sources. Wrapped in after_initialize so it
# runs after Zeitwerk has autoloaded the LinkedResource constant.
Rails.application.config.after_initialize do
  LinkedResource::Source.register :wikidata,
    name: "Wikidata",
    url_template: "https://www.wikidata.org/wiki/%{id}",
    id_pattern: /\AQ\d+\z/,
    icon: "wikidata",
    description: "Wikidata item corresponding to this record"
end
