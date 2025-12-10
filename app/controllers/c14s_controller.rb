class C14sController < ApplicationController
  include Pagy::Backend
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
      { sample: [
          :material,
          :taxon,
          :context
        ]
      },
      :references
    )

    # filter
    unless c14_params.blank?
      @c14s = @c14s.where(c14_params)
    end

    # if params[:sample_attributes][:context_attributes][:site_id].present?
    #   @c14s = @c14s.joins(sample: { context: :site }).where(sample:{context:{sites:{id: params[:sample_attributes][:context_attributes][:site_id]}}})
    # end

    # order
    if params.has_key?(:c14s_order_by)
      order = { params[:c14s_order_by] => params.fetch(:c14s_order, "asc") }
      @c14s = @c14s.reorder(order)
    end

    respond_to do |format|
      format.html {
        @pagy, @c14s = pagy(@c14s)
      }
      format.json
      format.csv {
        @c14s = @c14s.select(index_csv_template)
        render csv: @c14s
      }
    end
  end

  # GET /c14s/search
  # GET /c14s/search.json
  def search
    @c14s = C14.search(params[:q])

    respond_to do |format|
      format.html {
        @pagy, @c14s = pagy(@c14s)
        render :index
      }
      format.json  {
        render :index
      }
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
        format.html { redirect_to @c14, notice: 'Radiocarbon date created.' }
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
        format.html { redirect_to @c14, notice: 'Radiocarbon date saved.' }
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
      format.html { redirect_to c14s_url, notice: 'Radiocarbon date deleted.' }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_c14
      @c14 = C14.find(params[:id])
    end

    def set_site
      @site = Site.find(params[:site])
    end

    # Preload versions with their item for the show view (Bullet fix)
    def set_versions
      @versions = @c14.versions
                      .includes(:item)
                      .order(:created_at, :id)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
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