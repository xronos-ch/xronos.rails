<<<<<<< HEAD
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

=======
# == Schema Information
#
# Table name: wikidata_items
#
#  id                 :bigint           not null, primary key
#  qid                :integer
#  wikidata_link_type :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  wikidata_link_id   :bigint
#
# Indexes
#
#  index_wikidata_items_on_qid                                      (qid)
#  index_wikidata_items_on_wikidata_link                            (wikidata_link_type,wikidata_link_id)
#  index_wikidata_items_on_wikidata_link_type_and_qid               (wikidata_link_type,qid)
#  index_wikidata_items_on_wikidata_link_type_and_wikidata_link_id  (wikidata_link_type,wikidata_link_id)
#
class WikidataItem < ApplicationRecord

  belongs_to :wikidata_link, polymorphic: true

>>>>>>> b23be7c (Create WikidataItem and add to sites)
end
