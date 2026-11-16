# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'ostruct'

# Looks up archaeological sites by their exact English Wikidata label.
module BatchMatchableToWikidata
  extend ActiveSupport::Concern

  ARCHAEOLOGICAL_SITE_WIKIDATA_ID = 'Q839954'

  class WikidataLookupFailed < StandardError; end

  class_methods do
    def wikidata_match_candidates_batch(sites)
      names = sites.map(&:name).compact_blank.uniq
      return {} if names.empty?

      literals = names.map { |name| "#{name.to_json}@en" }.join(' ')
      response = execute_sparql_request(build_sparql_query(literals))
      parse_wikidata_response(response)
    end

    # Builds the SPARQL query.
    def build_sparql_query(site_names)
      <<~SPARQL
        SELECT ?item ?itemLabel ?itemDescription ?name
               (CONCAT("https://www.wikidata.org/wiki/", SUBSTR(STR(?item), 32)) AS ?itemURL) WHERE {
          VALUES ?name { #{site_names} }
          ?item wdt:P31 wd:#{ARCHAEOLOGICAL_SITE_WIKIDATA_ID}.
          ?item rdfs:label ?name.
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
      SPARQL
    end

    # Executes the SPARQL request.
    def execute_sparql_request(sparql_query)
      url = URI("https://query.wikidata.org/sparql?query=#{URI.encode_www_form_component(sparql_query)}&format=json")
      request = Net::HTTP::Get.new(url)
      request['User-Agent'] = Xronos::USER_AGENT
      request['From'] = Xronos::CONTACT_EMAIL

      response = Net::HTTP.start(url.hostname, url.port, use_ssl: true, open_timeout: 2, read_timeout: 3) do |http|
        http.request(request)
      end
      raise WikidataLookupFailed, "Wikidata returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response
    end

    # Parses the response from Wikidata.
    def parse_wikidata_response(response)
      data = JSON.parse(response.body)

      data.fetch('results').fetch('bindings')
        .group_by { |result| result.dig('name', 'value') }
        .transform_values do |matches|
          matches.map do |match|
            OpenStruct.new(
              qid: match.dig('item', 'value')&.split('/')&.last,
              label: match.dig('itemLabel', 'value'),
              description: match.dig('itemDescription', 'value'),
              url: match.dig('itemURL', 'value')
            )
          end
        end
    rescue JSON::ParserError, KeyError => e
      raise WikidataLookupFailed, e.message
    end
  end
end
