# frozen_string_literal: true

module FactoryBot
  module_function

  # Generate a unique external_id for a linked_resource that matches the
  # source's id_pattern. Used by factory traits that need to create
  # linked_resources for several different sources in a single record.
  def external_id_for(source_name)
    case source_name
    when 'Wikidata'
      "Q#{Faker::Number.unique.number(digits: 6)}"
    when 'OpenContext'
      SecureRandom.uuid
    else
      # Pleiades, Vici.org, iDAI.gazetteer — bare integer ids
      Faker::Number.unique.number(digits: 6).to_s
    end
  end
end
