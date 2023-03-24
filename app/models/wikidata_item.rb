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

end
