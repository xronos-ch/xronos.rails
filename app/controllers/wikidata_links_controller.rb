class WikidataLinksController < ApplicationController
  load_and_authorize_resource

  before_action :set_wikidata_link, only: [:show, :edit, :update, :destroy]

  def show
    @wikidata_link.request_item
    if @wikidata_link.item.sitelink_title("enwiki").present?
      @wikidata_link.item.request_wikipedia_extract
    end

    render partial: "wikidata_link"
  end

  def new
  end

  def edit
  end

  def create
    @wikidata_link = WikidataLink.new(wikidata_link_params)

    respond_to do |format|
      if @wikidata_link.save
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :created, location: @wikidata_link }
      else
        format.html { render :new }
        format.json { render json: @wikidata_link.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @wikidata_link.update(wikidata_link_params)
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :ok, location: @wikidata_link }
      else
        format.html { render :edit }
        format.json { render json: @wikidata_link.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  private

  def set_wikidata_link
    @wikidata_link = WikidataLink.find(params[:id])
  end

  def wikidata_link_params
    params.require(:wikidata_link).permit([
      :qid, 
      :wikidata_linkable_type,
      :wikidata_linkable_id,
      :revision_comment
    ])
  end

  def success_notice
    @wikidata_link.wikidata_linkable_type +
      ":" +
      @wikidata_link.wikidata_linkable_id.to_s +
      " is now linked to Wikidata item Q" +
      @wikidata_link.qid.to_s
  end

end
