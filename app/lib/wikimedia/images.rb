# frozen_string_literal: true

module Wikimedia
  ##
  # Wikidata P18 (image) lookup. Returns up to +MAX_IMAGES+ image hashes
  # derived from the +Wikidata::Property::CommonsMedia+ claims on a given
  # QID, or an empty array on any error (including a missing/invalid QID).
  module Images
    CACHE_TTL = 30.days
    NIL_CACHE_TTL = 1.hour
    MAX_IMAGES = 5
    THUMB_SIZE = 500

    def self.for(qid)
      return [] if qid.blank?

      key = cache_key(qid)
      return Rails.cache.read(key) if Rails.cache.exist?(key)

      result = fetch(qid)
      Rails.cache.write(key, result, expires_in: result.empty? ? NIL_CACHE_TTL : CACHE_TTL)
      result
    end

    def self.cache_key(qid)
      "wikidata_images/#{qid}"
    end

    def self.fetch(qid)
      item = Wikidata::Item.find(qid)
      return [] if item.nil?

      item.properties('P18').first(MAX_IMAGES).map { |img| build_image_hash(img) }
    rescue StandardError => e
      Rails.logger.error("[Wikidata] images #{qid} failed: #{e.class} #{e.message}")
      []
    end

    def self.build_image_hash(img)
      {
        basename:  img.basename,
        extension: img.extension,
        thumb_url: img.url(THUMB_SIZE),
        page_url:  img.page_url
      }
    end
  end
end
