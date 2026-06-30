# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'ostruct'

##
# BatchMatchableToWikidata
#
# Provides SPARQL-based batch matching of records against Wikidata
# archaeological-site items (P31 = Q839954). For each record in a
# collection that does not yet have a Wikidata linked resource, the
# concern queries Wikidata by the record's +name+ and creates a pending
# +LinkedResource+ for each match. Curators can then review and approve
# the pending records from the dashboard.
#
# The host model is expected to provide:
#   - a +linked_resources+ association (e.g. +has_many :linked_resources,
#     as: :linkable+)
#   - a +name+ attribute used as the SPARQL search key
#
# When attaching to additional models, override +ARCHAEOLOGICAL_SITE_WIKIDATA_ID+
# or pass a different +wd:QID+ if matching against a non-archaeological
# Wikidata class.
module BatchMatchableToWikidata

  extend ActiveSupport::Concern

  ARCHAEOLOGICAL_SITE_WIKIDATA_ID = 'Q839954'.freeze

  class_methods do
    # For each record in +sites+ that doesn't yet have a Wikidata link,
    # query Wikidata's SPARQL endpoint for matching archaeological site
    # items by name. Create pending LinkedResource records for each
    # match. Returns the parsed response grouped by record name.
    def wikidata_match_candidates_batch(sites)
      sites_without_wikidata_link = sites.select do |site|
        site.linked_resources.where(source: "Wikidata").empty?
      end

      return [] if sites_without_wikidata_link.empty?

      site_names = extract_site_names(sites_without_wikidata_link)
      sparql_query = build_sparql_query(site_names)
      response = execute_sparql_request(sparql_query)
      wikidata_results = parse_wikidata_response(response)

      wikidata_results.each do |site_name, matches|
        site = sites_without_wikidata_link.find { |s| s.name == site_name }
        next unless site

        matches.each do |match|
          site.linked_resources.find_or_create_by(source: "Wikidata", external_id: match.qid) do |linked_resource|
            linked_resource.data = {
              label: match.label,
              description: match.description
            }
            linked_resource.save!
          end
        end
      end

      wikidata_results # Return results for reference
    end

    # Generate a unique cache key for a batch of sites.
    def generate_cache_key(sites)
      site_names = sites.pluck(:name).compact.reject(&:blank?) # Remove nil and blank names
      "wikidata_match_batch/#{Digest::MD5.hexdigest(site_names.sort.join(','))}"
    end

    # Extracts names from the sites.
    def extract_site_names(sites)
      sites.pluck(:name).map { |name| "\"#{name}\"@en" }.join(" ")
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

      Net::HTTP.start(url.hostname, url.port, use_ssl: true, open_timeout: 2, read_timeout: 3) do |http|
        if Rails.env.development?
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.request(request)
      end

    rescue OpenSSL::SSL::SSLError => e
      if Rails.env.development?
        Rails.logger.warn("Wikidata SSL error in dev: #{e.class} - #{e.message}")
        OpenStruct.new(body: '{"results":{"bindings":[]}}')
      else
        raise
      end

    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
      Rails.logger.warn "Wikidata lookup failed: #{e.class} – #{e.message}"
      OpenStruct.new(body: '{"results":{"bindings":[]}}')
    end

    # Parses the response from Wikidata.
    def parse_wikidata_response(response)
      data = JSON.parse(response.body)

      data["results"]["bindings"]
        .group_by { |result| result.dig("name", "value") }
        .transform_values do |matches|
          matches.map do |match|
            OpenStruct.new(
              qid: match.dig("item", "value")&.split("/")&.last,
              label: match.dig("itemLabel", "value"),
              description: match.dig("itemDescription", "value"),
              url: match.dig("itemURL", "value")
            )
          end
        end
    end
  end
end
