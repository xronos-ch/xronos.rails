class SitesController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_site, only: [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html
      format.json { render json: DataDatatable.new(params) }
    end
  end

  # GET /sites
  # GET /sites.json
  def index
    @pagy, @sites = pagy(Site.all.order(:name))
    #@sites = Site.all
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
    gon.selected_sites = [{id: @site.id, name: @site.name, lat: @site.lat, lng: @site.lng}].to_json
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
        format.html { redirect_to @site, notice: 'Site was successfully updated.' }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        format.json { render json: @site.errors, status: :unprocessable_entity }
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
      params.require(:site).permit(
        :id,
        :name,
        :lat,
        :lng,
        :country_code,
        :_destroy
      )
    end
end
