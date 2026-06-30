# frozen_string_literal: true

##
# Site::Description
#
# Composes a site's Wikipedia lead excerpt from the Wikimedia APIs via the
# +Wikipedia::Article+ and +Wikimedia::Sitelinks+ lib clients. Caches both
# the data and the fetch timestamp.
class Site::Description # rubocop:disable Style/ClassAndModuleChildren
  CACHE_TTL = 7.days

  attr_reader :lod_link, :lang

  def initialize(lod_link:, lang: 'en')
    @lod_link = lod_link
    @lang = lang
  end

  def cache_key
    "site_description/#{lod_link.id}/#{lod_link.updated_at.to_i}/#{lang}"
  end

  def cached?
    Rails.cache.exist?(cache_key)
  end

  def data
    cached[:data]
  end

  def fetched_at
    cached[:fetched_at]
  end

  def failed?
    data[:wikipedia_extract_text].blank?
  end

  private

  def cached
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      { data: build_data, fetched_at: Time.current }
    end
  end

  def build_data
    lang_title = (Wikimedia::Sitelinks.for(lod_link.qcode, lang: lang) || {})[:lang_title]

    {
      wikipedia_title: lang_title,
      wikipedia_extract_text: fetch_wikipedia_extract(lang_title),
      wikipedia_url: wikipedia_url_for(lang_title)
    }
  end

  def fetch_wikipedia_extract(title)
    return nil if title.blank?

    Wikipedia::Article.summary(title, lang: lang)&.dig(:text)
  end

  def wikipedia_url_for(title)
    return nil if title.blank?

    Wikipedia::Article.url(title, lang: lang)
  end
end
