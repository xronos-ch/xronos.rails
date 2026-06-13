require "net/http"
require "json"

##
# gbif.rb
#
# Minimal Ruby wrappers for the GBIF API: https://techdocs.gbif.org/en/openapi/
#
# Example:
#   Gbif::Species.match(scientificName: "Quercus robur")
#
module GBIF
  BASE_URL = "https://api.gbif.org"

  ##
  # GBIF species API: https://techdocs.gbif.org/en/openapi/v1/species
  module Species

    ##
    # Get by usageKey (/v1/species/{usageKey})
    def self.usage(usageKey)
      get("v1/species/#{usageKey}")
    end

    ##
    # Fuzzy name match service (/v2/species/match)
    def self.match(**params)
      get("v2/species/match", params)
    end

    ##
    # Full text search over name usages (v1/species/search
    def self.search(query:, limit: 10)
      get("v1/species/search", q: query, limit: limit)
    end

    # GET with caching
    def self.get(path, params = {})
      key = cache_key(path, params)

      Rails.cache.fetch(key, expires_in: 24.hours) do
        perform_get_request(path, params)
      end
    end

    private

    def self.perform_get_request(path, params)
      uri = URI("#{BASE_URL}/#{path}")

      query = params.compact.transform_keys(&:to_s)
      uri.query = URI.encode_www_form(query) if query.any?

      Rails.logger.debug("[GBIF] GET #{uri}")

      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error(
          "[GBIF] GET #{path} failed: #{response.code} #{response.body}"
        )
        return nil
      end

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[GBIF] GET #{path} error: #{e.class} #{e.message}")
      nil
    end

    def self.cache_key(path, params)
      normalised = params
        .compact
        .transform_keys(&:to_s)
        .sort
        .to_h

      digest = Digest::SHA256.hexdigest(normalised.to_json)

      "gbif/#{path}/#{digest}"
    end
  end
end

