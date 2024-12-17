class WikidataItem
  attr_reader :wikipedia_extract

  SITE_URL = {
    enwiki: "https://en.wikipedia.org/wiki/",
    commonswiki: "https://commons.wikipedia.org/wiki/"
  }.with_indifferent_access

  def initialize(qid)
    attributes = Wikidata::Item.find(prepend_q(qid))
    attributes.each do |attr,val|
      instance_variable_set("@#{attr}", val)
    end
  end

  def label(lang = "en")
    @labels[lang].value
  end

  def sitelink_title(site = "enwiki")
    @sitelinks[site]["title"]
  end

  def sitelink_url(site = "enwiki")
    return nil unless SITE_URL.has_key?(site)
    SITE_URL[site] + (ERB::Util.url_encode sitelink_title(site))
  end

  def request_wikipedia_extract(lang = "en")
    title = sitelink_title(lang + "wiki")
    @wikipedia_extract = WikipediaExtract.new(title, lang)
  end

  protected

  def prepend_q(qid)
    qid = qid.to_s
    qid = "Q" + qid unless qid.starts_with?("Q")
  end
end