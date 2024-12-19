require 'csv'

class DendrosController < ApplicationController
  include Tabulatable
  include Pagy::Backend

  load_and_authorize_resource
  
  before_action :set_dendro, only: %i[ show edit update destroy ]
  before_action :set_site, only: [ :new ]

  # GET /dendros or /dendros.json
  def index
    @dendros = Dendro.includes(
      {sample: [
        :material,
        :taxon,
        :context
      ]},
      :references
    )

    # filter
    unless dendro_params.blank?
      @dendros = @dendros.where(dendro_params)
    end
    
#    if params[:sample_attributes][:context_attributes][:site_id].present?
#      @dendros = @dendros.joins(sample: { context: :site }).where(sample:{context:{sites:{id: params[:sample_attributes][:context_attributes][:site_id]}}})
#    end
        
    # order
    if params.has_key?(:dendros_order_by)
      order = { params[:dendros_order_by] => params.fetch(:dendros_order, "asc") }
      @dendros = @dendros.reorder(order)
    end

    respond_to do |format|
      format.html {
        @pagy, @dendros = pagy(@dendros)
      }
      format.json
      format.csv {
        @dendros = @dendros.select(index_csv_template)
        render csv: @dendros
      }
    end
  end

  # GET /dendros/1 or /dendros/1.json
  def show
  end

  # GET /dendros/new
  def new
    @dendro = Dendro.new
    @dendro.build_sample.build_context(site: @site)
  end

  # GET /dendros/1/edit
  def edit
  end

  # POST /dendros or /dendros.json
  def create
    @dendro = Dendro.new(dendro_params)

    respond_to do |format|
      if @dendro.save
        format.html { redirect_to @dendro, notice: "Dendro was successfully created." }
        format.json { render :show, status: :created, location: @dendro }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dendro.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dendros/1 or /dendros/1.json
  def update
    respond_to do |format|
      if @dendro.update(dendro_params)
        format.html { redirect_to @dendro, notice: "Dendro was successfully updated." }
        format.json { render :show, status: :ok, location: @dendro }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dendro.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dendros/1 or /dendros/1.json
  def destroy
    @dendro.destroy

    respond_to do |format|
      format.html { redirect_to dendros_path, status: :see_other, notice: "Dendro was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  def export_measurements_csv
    @dendro = Dendro.find(params[:id])

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["Year", "Width (mm)"]
      @dendro.measurements.each do |measurement|
        csv << [measurement["year"], measurement["value"]]
      end
    end
    
    file_name = "dendro_measurements_#{@dendro.series_code.parameterize}.csv"
    
    respond_to do |format|
      format.csv { send_data csv_data, filename: file_name }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dendro
      @dendro = Dendro.find(params[:id])
    end
    
    def set_site
      @site = Site.find(params[:site])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dendro_params
      params.fetch(:dendro, {}).permit(
      :sample_id,
      :series_code,
      :name,
      :description,
      :start_year,
      :end_year,
      :is_anchored,
      :waney_edge,
      :offset,
      :measurements,
        {sample_attributes: [
          :id,
          :material_id,
          :taxon_id,
          :context_id,
          {context_attributes: [
            :id,
            :name,
            :approx_start_time,
            :approx_end_time,
            :site_id
          ]},
          :position_description,
          :position_x,
          :position_y,
          :position_z,
          :position_crs
        ]},
        sample: [
          :context_id,
          contexts: [
            :site_id
          ]
        ]
      )
    end
end
