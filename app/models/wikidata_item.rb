class WikidataItem
  attr_reader :wikipedia_extract

  validates :qid, presence: true

  belongs_to :wikidata_link, polymorphic: true

  SITE_URLS = {
    enwiki: "https://en.wikipedia.org/wiki/",
    commonswiki: "https://commons.wikipedia.org/wiki/"
  }

  def qcode
    "Q#{qid}"
  end

  def url
    "https://www.wikidata.org/wiki/#{qcode}"
  end

  def item
    Wikidata::Item.find qcode
  end

  def label(lang = "en")
    item.labels[lang].value
  end

  def sitelink_title(site = "enwiki")
    item.sitelinks[site]["title"]
  end

  def sitelink_url(site = "enwiki")
    return nil unless SITE_URLS.with_indifferent_access.has_key?(site)
    SITE_URLS.with_indifferent_access[site] + (ERB::Util.url_encode sitelink_title(site))
  end

end
