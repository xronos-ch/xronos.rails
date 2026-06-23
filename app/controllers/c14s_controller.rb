class C14sController < ApplicationController
  include Tabulatable

  load_and_authorize_resource

  before_action :set_c14, only: [:show, :edit, :update, :destroy]
  before_action :set_site, only: [:new]
  before_action :set_versions, only: [:show]

  # GET /c14s
  # GET /c14s.json
  # GET /c14s.csv
  def index
    @c14s = C14.includes(
      {
        sample: [
          :material,
          :taxon,
          { context: :site }
        ]
      },
      :references
    )

    # filter
    unless c14_params.blank?
      @c14_params = c14_params
      @c14s = @c14s.where(c14_params)
    end

    respond_to do |format|
      format.html do
        # Sorting is only applied to the interactive HTML table.
        # CSV exports deliberately ignore arbitrary ordering parameters.
        if params.has_key?(:c14s_order_by)
          order = { params[:c14s_order_by] => params.fetch(:c14s_order, "asc") }
          @c14s = @c14s.reorder(order)
        end

        begin
          @pagy, @c14s = pagy(:countish, @c14s)
        rescue Pagy::OverflowError
          head :not_found
        end
      end

      format.json

      format.csv do
        # Public CSV export remains available, but does not honour pagination
        # or arbitrary sorting parameters from crawlers/bots.
        @c14s = @c14s.reorder(:id).select(index_csv_template)
        render csv: @c14s
      end
    end
  end

  # GET /c14s/search
  # GET /c14s/search.json
  def search
    @c14s = C14.search(params[:q])

    respond_to do |format|
      format.html do
        begin
          @pagy, @c14s = pagy(:countish, @c14s)
        rescue Pagy::OverflowError
          head :not_found
        end

        render :index unless performed?
      end

      format.json do
        render :index
      end
    end
  end

  # GET /c14s/1
  # GET /c14s/1.json
  def show
    @calibration = @c14.calibration
    @calibration.calibrate if @calibration.present?
  end

  # GET /c14s/new
  def new
    @context = @site.contexts.build
    @sample  = @context.samples.build
    @c14     = @sample.c14s.build
  end

  # GET /c14s/1/edit
  def edit
  end

  # POST /c14s
  # POST /c14s.json
  def create
    @c14 = C14.new(c14_params)

    respond_to do |format|
      if @c14.save
        format.html { redirect_to @c14, notice: "Radiocarbon date created." }
        format.json { render :show, status: :created, location: @c14 }
      else
        format.html { render :new }
        format.json { render json: @c14.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /c14s/1
  # PATCH/PUT /c14s/1.json
  def update
    respond_to do |format|
      if @c14.update(c14_params)
        format.html { redirect_to @c14, notice: "Radiocarbon date saved." }
        format.json { render json: @c14, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @c14.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /c14s/1
  # DELETE /c14s/1.json
  def destroy
    @c14.destroy

    respond_to do |format|
      format.html { redirect_to c14s_url, notice: "Radiocarbon date deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_c14
    @c14 = C14.find(params[:id])
  end

  def set_site
    @site = Site.find(params[:site])
  end

  def set_versions
    @versions = @c14.versions
                    .order(:created_at, :id)
  end

  def c14_params
    params.fetch(:c14, {}).permit(
      :lab_identifier,
      :c14_lab_id,
      :bp,
      :std,
      :delta_c13,
      :delta_c13_std,
      :method,
      :sample_id,
      {
        sample_attributes: [
          :id,
          :material_id,
          :taxon_id,
          :context_id,
          {
            context_attributes: [
              :id,
              :name,
              :approx_start_time,
              :approx_end_time,
              :site_id
            ]
          },
          :position_description,
          :position_x,
          :position_y,
          :position_z,
          :position_crs
        ]
      },
      sample: [
        :context_id,
        contexts: [
          :site_id
        ]
      ]
    )
  end
end
