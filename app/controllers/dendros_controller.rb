require 'csv'

class DendrosController < ApplicationController
  include Tabulatable
  include SupersedableController

  load_and_authorize_resource except: :export_measurements_csv

  before_action :set_dendro, only: %i[ show edit update destroy ]
  before_action :set_site, only: [ :new ]

  include MergeableController

  # GET /dendros or /dendros.json
  def index
    filters = params.fetch(:dendro, ActionController::Parameters.new).permit(
      :sample_id, :series_code, :name, :measurement_variable, :measurement_unit, :is_anchored, :waney_edge,
      sample: [:context_id, { contexts: [:site_id] }]
    )
    sample_filter = filters.delete(:sample)
    site_id = params[:site_id].presence || sample_filter&.dig(:contexts, :site_id)
    @dendros = Dendro.includes(:references, sample: { context: :site }).where(filters.to_h)
    @dendros = @dendros.where(sample_id: Sample.where(context_id: sample_filter[:context_id])) if sample_filter&.[](:context_id).present?
    if site_id.present?
      @dendros = @dendros.where(sample_id: Sample.where(context: Context.where(site_id: site_id)))
    end

    respond_to do |format|
      format.html do
        @dendros = Dendro.sort_series(@dendros, params[:dendros_order_by], params[:dendros_order])
        @pagy, @dendros = pagy(:countish, @dendros)
      rescue Pagy::OverflowError
        head :not_found
      end
      format.json
      format.csv do
        validate_csv_params!
        next if performed?

        render csv: @dendros.except(:includes).reorder(:id).select(*Dendro::EXPORT_COLUMNS)
      end
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
    authorize_association_changes

    respond_to do |format|
      if @dendro.save
        format.html { redirect_to @dendro, notice: "Dendro was successfully created." }
        format.json { render :show, status: :created, location: @dendro }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
        format.json { render json: @dendro.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dendros/1 or /dendros/1.json
  def update
    @dendro.assign_attributes(dendro_params)
    authorize_association_changes

    respond_to do |format|
      if @dendro.save
        format.html { redirect_to @dendro, notice: "Dendro was successfully updated." }
        format.json { render :show, status: :ok, location: @dendro }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
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
    @dendro = Dendro.unscoped.find(params[:id]).ultimately_superseded_by
    authorize! :read, @dendro

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[position calendar_year value measurement_variable measurement_unit]
      @dendro.series_points.each do |point|
        csv << [point["position"], point["calendar_year"], point["value"],
                @dendro.measurement_variable, @dendro.measurement_unit]
      end
    end

    file_name = "dendro_measurements_#{@dendro.series_code.parameterize}.csv"

    respond_to do |format|
      format.csv { send_data csv_data, filename: file_name }
    end
  end

  private

    def authorize_association_changes
      sample = @dendro.sample
      context = sample&.context
      authorize! :update, sample if sample&.persisted? && sample.changed?
      authorize! :update, context if context&.persisted? && context.changed?
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_dendro
      @dendro = Dendro.find(params[:id])
    end

    def set_site
      if params[:site].blank?
        redirect_to sites_path, notice: "Choose a site, then select Add dendrochronological series."
        return
      end

      @site = Site.find(params[:site])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dendro_params
      params.fetch(:dendro, {}).permit(
      :sample_id,
      :series_code,
      :name,
      :description,
      :anchor_position,
      :anchor_year,
      :measurement_variable,
      :measurement_unit,
      :is_anchored,
      :waney_edge,
      :object_title,
      :object_type,
      :object_description,
      :object_dimensions,
      :project_title,
      :project_objective,
      :project_start_date,
      :project_end_date,
      :wood_completeness,
      :parameters,
      :measurements_text,
      :measurements,
        { measurements: [:position, :value] },
        {sample_attributes: [
          :id,
          :name,
          :part_of_organism,
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
      ).tap { |attributes| normalize_context_selection(attributes) }
    end

    def normalize_context_selection(attributes)
      sample = attributes[:sample_attributes]
      return unless sample && sample[:context_id].present? && sample[:context_attributes]

      sample[:context_attributes] = sample[:context_attributes]
                                    .slice(:approx_start_time, :approx_end_time)
                                    .merge(id: sample[:context_id])
    end
end
