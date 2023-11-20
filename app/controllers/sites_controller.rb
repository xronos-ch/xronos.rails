class SitesController < ApplicationController
  include Tabulatable
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  def index
    @sites = Site.with_counts

    # filter
    unless site_params.blank?
      @sites = @sites.where(site_params)
    end

    # order
    if params.has_key?(:sites_order_by)
      order = { params[:sites_order_by] => params.fetch(:sites_order, "asc") }
      @sites = @sites.reorder(order)
    end

    respond_to do |format|
      format.html { 
        @pagy, @sites = pagy(@sites)
      }
      format.json
      format.csv {
        @sites = @sites.select(index_csv_template)
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
    if params.has_key?(:c14s_order_by)
      order = { params[:c14s_order_by] => params.fetch(:c14s_order, "asc") }
      @c14s = @c14s.reorder(order)
    end

    @typos = @site.typos.includes([:references])
    if params.has_key?(:typos_order_by)
      order = { params[:typos_order_by] => params.fetch(:typos_order, "asc") }
      @typos = @typos.reorder(order)
    end

    respond_to do |format|
      format.html {
        @pagy_c14s, @c14s = pagy(@c14s, page_param: :c14s_page)
        @pagy_typos, @typos = pagy(@typos, page_param: :typos_page)
      }
      format.json
    end
  end

  # GET /sites/new
  def new
    @site = Site.new
    @site.build_country
  end

  # GET /sites/1/edit
  def edit
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
        format.html { redirect_to @site, notice: "Saved changes to #{@site.name}." }
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
