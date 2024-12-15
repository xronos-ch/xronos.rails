class LodLinksController < ApplicationController
  load_and_authorize_resource

  before_action :set_lod_link, only: [:show, :edit, :update, :destroy]

  def show
    @wikidata_link.request_item
    if @wikidata_link.item.sitelink_title("enwiki").present?
      @wikidata_link.item.request_wikipedia_extract
    end

    render partial: "lod_link"
  end

  def new
  end

  def edit
  end

  def create
    @lod_link = LodLink.new(lod_link_params)

    respond_to do |format|
      if @lod_link.save
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :created, location: @lod_link }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @lod_link.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @lod_link.update(lod_link_params)
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :ok, location: @lod_link }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @lod_link.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  private

  def set_lod_link
    @lod_link = LodLink.find(params[:id])
    @wikidata_link = LodLink.where(source: "Wikidata").find(params[:id])
  end

  def lod_link_params
    params.require(:lod_link).permit([
      :external_id,
      :source, 
      :linkable_type,
      :linkable_id,
      :revision_comment
    ])
  end

  def success_notice
    @lod_link.linkable_type +
      ":" +
      @lod_link.linkable_id.to_s +
      " is now linked to Wikidata item Q" +
      @lod_link.external_id.to_s
  end
end
