class SitesController < ApplicationController
  include Tabulatable
  include Pagy::Backend

  SITE_TABLE_PREVIEW_LIMIT = 20

  load_and_authorize_resource

  before_action :reject_table_params_on_show!, only: [:show]
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  # GET /sites.csv
  def index
    @sites = Site.with_counts

    # filter
    unless site_params.blank?
      @sites = @sites.where(site_params)
    end

    respond_to do |format|
      format.html do
        # Sorting is only applied to the interactive HTML table.
        # CSV exports deliberately ignore arbitrary ordering parameters.
        if params.has_key?(:sites_order_by)
          order = { params[:sites_order_by] => params.fetch(:sites_order, "asc") }
          @sites = @sites.reorder(order)
        end

        @pagy, @sites = pagy(@sites)
      end

      format.json

      format.csv do
        # Public CSV export remains available, but does not honour pagination
        # or arbitrary sorting parameters from crawlers/bots.
        @sites = @sites.reorder(:id).select(index_csv_template)
        render csv: @sites
      end
    end
  end

  # GET /sites/search
  # GET /sites/search.json
  def search
    @sites = Site.search(params[:q])

    respond_to do |format|
      format.html do
        @pagy, @sites = pagy(@sites.order(:name))
        render :index
      end

      format.json do
        render :index
      end
    end
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
    c14s_scope = @site.c14s.includes(
      :references,
      sample: [
        :material,
        :taxon,
        { context: :site }
      ]
    )

    typos_scope = @site.typos.includes(:references)

    respond_to do |format|
      format.html do
        @c14s_count = @site.c14s.count
        @typos_count = @site.typos.count

        @c14s = c14s_scope
                  .reorder(:id)
                  .limit(SITE_TABLE_PREVIEW_LIMIT)

        @typos = typos_scope
                   .reorder(:id)
                   .limit(SITE_TABLE_PREVIEW_LIMIT)
      end

      format.json do
        @c14s = c14s_scope
        @typos = typos_scope
      end
    end
  end

  # GET /sites/new
  def new
    @site = Site.new
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
        format.html { redirect_to site_path(@site), notice: "Site created." }
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
        format.html { redirect_back fallback_location: root_path, notice: "Saved changes to #{@site.name}." }
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
      format.html { redirect_back fallback_location: root_path, notice: "Site was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_site
    @site = Site.find(params[:id])
    @wikidata_matches = Site.wikidata_match_candidates_batch([@site]) || {}
  end

  def reject_table_params_on_show!
    forbidden = %i[
      c14s_page
      typos_page
      c14s_order
      typos_order
      c14s_order_by
      typos_order_by
    ]

    return unless forbidden.any? { |key| params.key?(key) }

    redirect_to site_path(params[:id]), status: :moved_permanently
  end

  def site_params
    params.fetch(:site, {}).permit(
      :id,
      :name,
      :lat,
      :lng,
      { site_type_ids: [] },
      :country_code,
      :revision_comment,
      :_destroy,
      wikidata_link_attributes: [:qid]
    )
  end
end