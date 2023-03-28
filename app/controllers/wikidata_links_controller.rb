class WikidataLinksController < ApplicationController
  load_and_authorize_resource

  def show
    @wikidata_link.request_item
    if @wikidata_link.item.sitelink_title("enwiki").present?
      @wikidata_link.item.request_wikipedia_extract
    end

    render partial: "wikidata_link"
  end
end
