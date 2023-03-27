class WikidataLinksController < ApplicationController
  load_and_authorize_resource

  def show
    @wikidata_link.request_item
    render partial: "wikidata_link"
  end
end
