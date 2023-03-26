# == Schema Information
#
# Table name: wikidata_links
#
#  id                     :bigint           not null, primary key
#  qid                    :integer
#  wikidata_linkable_type :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  wikidata_linkable_id   :bigint
#
# Indexes
#
#  index_wikidata_links_on_linkable_type_and_linkable_id  (wikidata_linkable_type,wikidata_linkable_id)
#  index_wikidata_links_on_qid                            (qid)
#  index_wikidata_links_on_wikidata_linkable              (wikidata_linkable_type,wikidata_linkable_id)
#
class WikidataLink < ApplicationRecord
  BASE_URL = "https://www.wikidata.org/wiki/"
  SITE_URL = {
    enwiki: "https://en.wikipedia.org/wiki/",
    commonswiki: "https://commons.wikipedia.org/wiki/"
  }

  attr_reader :item

  validates :qid, presence: true

  belongs_to :wikidata_linkable, polymorphic: true

  def qcode
    "Q#{qid}"
  end

  def url
    Wikidata::BASE_URL + qcode
  end

  def request_item
    @item = Wikidata::Item.find qcode
  end

  def label(lang = "en")
    item.labels[lang].value
  end

  def sitelink_title(site = "enwiki")
    item.sitelinks[site]["title"]
  end

  def sitelink_url(site = "enwiki")
    return nil unless Wikidata::SITE_URL.with_indifferent_access.has_key?(site)
    Wikidata::SITE_URL.with_indifferent_access[site] + (ERB::Util.url_encode sitelink_title(site))
  end

end
