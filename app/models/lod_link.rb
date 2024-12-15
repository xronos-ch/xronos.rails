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
class LodLink < ApplicationRecord
  include Turbo::Broadcastable
  include Versioned

  BASE_URL = "https://www.wikidata.org/wiki/"
  SITE_URL = {
    enwiki: "https://en.wikipedia.org/wiki/",
    commonswiki: "https://commons.wikipedia.org/wiki/"
  }

  attr_reader :item

  validates :external_id, presence: true, numericality: { only_integer: true }
  validates :source, presence: true

  belongs_to :linkable, polymorphic: true

  def qcode
    "Q#{external_id}"
  end

  def url
    BASE_URL + qcode
  end

  def request_item
    @item = WikidataItem.new(external_id)
  end

  def title
    item.present? ? item.label : qcode
  end

end
