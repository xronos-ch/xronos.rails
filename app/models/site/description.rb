# frozen_string_literal: true

##
# Site::Description
#
# Composes a site's Wikipedia lead excerpt and Wikidata-sourced image
# gallery from the Wikimedia APIs via the +Wikipedia::Article+,
# +Wikimedia::Sitelinks+ and +Wikimedia::Images+ lib clients. Caches both
# the data and the fetch timestamp.
class Site::Description # rubocop:disable Style/ClassAndModuleChildren
  CACHE_TTL = 7.days

  attr_reader :linked_resource, :lang

  def initialize(linked_resource:, lang: 'en')
    @linked_resource = linked_resource
    @lang = lang
  end

  def cache_key
    "site_description/#{linked_resource.id}/#{linked_resource.updated_at.to_i}/#{lang}"
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
    data[:wikipedia_extract_text].blank? && data[:images].empty?
  end

  private

  def cached
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      { data: build_data, fetched_at: Time.current }
    end
  end

  def build_data
    sitelinks = Wikimedia::Sitelinks.for(linked_resource.qcode, lang: lang) || {}
    lang_title = sitelinks[:lang_title]
    commons_title = sitelinks[:commons_title]

    {
      wikipedia_title: lang_title,
      wikipedia_extract_text: fetch_wikipedia_extract(lang_title),
      wikipedia_url: wikipedia_url_for(lang_title),
      images: Wikimedia::Images.for(linked_resource.qcode),
      commons_category_url: commons_category_url_for(commons_title),
      commons_category_title: commons_category_title_for(commons_title)
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

  def commons_category_url_for(title)
    return nil if title.blank?

    "https://commons.wikimedia.org/wiki/#{title.tr(' ', '_')}"
  end

  def commons_category_title_for(title)
    return nil if title.blank?

    title.sub(/\ACategory:/, '').tr('_', ' ')
  end
end
