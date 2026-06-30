# frozen_string_literal: true

module Wikimedia
  ##
  # Wikidata sitelinks lookup. Returns +lang_title+ (the Wikipedia article
  # title for the requested language) and +commons_title+ (the Commons
  # category title), or nil on any error (including a missing/invalid QID).
  module Sitelinks
    CACHE_TTL = 30.days
    NIL_CACHE_TTL = 1.hour

    def self.for(qid, lang: 'en')
      return nil if qid.blank?

      key = cache_key(qid, lang)
      return Rails.cache.read(key) if Rails.cache.exist?(key)

      result = fetch(qid, lang)
      Rails.cache.write(key, result, expires_in: result.nil? ? NIL_CACHE_TTL : CACHE_TTL)
      result
    end

    def self.cache_key(qid, lang)
      "wikidata_sitelinks/#{qid}/#{lang}"
    end

    def self.fetch(qid, lang)
      item = Wikidata::Item.find(qid)
      return nil if item.nil?

      enwiki = item.sitelinks["#{lang}wiki"]
      commons = item.sitelinks['commonswiki']

      # Hash-style access: wikidata-client returns nested Hashie::Mash
      # instances whose +.title+ triggers +Entity#title+'s infinite
      # recursion when the entity has no English label/en sitelink.
      {
        lang_title:    enwiki ? enwiki['title'] : nil,
        commons_title: commons ? commons['title'] : nil
      }
    rescue StandardError => e
      Rails.logger.error("[Wikidata] sitelinks #{qid} failed: #{e.class} #{e.message}")
      nil
    end
  end
end
