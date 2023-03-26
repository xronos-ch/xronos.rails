class RequestWikidataItemJob < ApplicationJob
  queue_as :default

  def perform(wikidata_link)
    wikidata_link.request_item
  end
end
