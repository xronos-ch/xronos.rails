class SitesController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  def index
    unless site_params.blank?
      @sites = Site.all.where(site_params)
    end

    respond_to do |format|
      format.html { 
        @pagy, @sites = pagy(Site.all.order(:name))
        render :index
      }
      format.json
      format.csv {
        render csv: @sites
      }
    end
  end

  # GET /sites/search
  # GET /sites/search.json
  def search
    @sites = Site.search(params[:q])

    respond_to do |format|
      format.html { 
        @pagy, @sites = pagy(@sites.order(:name))
        render :index
      }
      format.json  {
        render :index
      }
    end
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
    @site = Site.find(params[:id])
    @c14s = @site.c14s.includes([:references, sample: [ :material, :taxon, :context ]])
    @typos = @site.typos.includes([:references])
  end

  # GET /sites/new
  def new
    @site = Site.new
    @site.build_country
  end

  # GET /sites/1/edit
  def edit
    gon.selected_sites = [{id: @site.id, name: @site.name, lat: @site.lat, lng: @site.lng}].to_json
  end

  # POST /sites
  # POST /sites.json
  def create
    @site = Site.new(site_params)

    respond_to do |format|
      if @site.save
        format.html { redirect_to @site, notice: 'Site was successfully created.' }
        format.json { render :show, status: :created, location: @site }
      else
        format.html { render :new }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_back(fallback_location: @site, notice: "Saved changes to #{@site.name}.") }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        format.json { render json: @site.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: 'Site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.fetch(:site, {}).permit(
        :q,
        :id,
        :name,
        :lat,
        :lng,
        {site_type_ids: []},
        :country_code,
        :_destroy
      )
    end
end
