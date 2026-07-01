# frozen_string_literal: true

module Wikipedia
  USER_AGENT = 'XRONOS <https://xronos.ch>'

  module Article
    CACHE_TTL = 7.days
    NIL_CACHE_TTL = 1.hour

    def self.summary(title, lang: 'en')
      return nil if title.blank?

      key = cache_key(title, lang)
      return Rails.cache.read(key) if Rails.cache.exist?(key)

      result = fetch(title, lang)
      Rails.cache.write(key, result, expires_in: result.nil? ? NIL_CACHE_TTL : CACHE_TTL)
      result
    end

    def self.url(title, lang: 'en')
      "https://#{lang}.wikipedia.org/wiki/#{ERB::Util.url_encode(title)}"
    end

    def self.cache_key(title, lang)
      "wikipedia_article/#{lang}/#{ERB::Util.url_encode(title)}"
    end

    def self.fetch(title, lang)
      page = client(lang).find(title,
                               prop: %w[extracts fullurl],
                               exintro: true,
                               explaintext: true)
      return nil if page.nil?

      {
        title: page.title,
        text: page.summary.to_s.split("\n", 2).first.presence,
        url: page.fullurl
      }
    rescue StandardError => e
      Rails.logger.error("[Wikipedia] fetch #{lang}/#{title} failed: #{e.class} #{e.message}")
      nil
    end

    def self.client(lang)
      Wikipedia::Client.new(Wikipedia::Configuration.new(domain: "#{lang}.wikipedia.org"))
    end
  end
end
