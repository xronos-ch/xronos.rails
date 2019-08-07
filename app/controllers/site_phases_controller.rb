class SitePhasesController < ApplicationController
  load_and_authorize_resource

  before_action :set_site_phase, only: [:show, :edit, :update, :destroy]

  # GET /site_phases
  # GET /site_phases.json
  def index
    @site_phases = SitePhase.all
  end

  # GET /site_phases/1
  # GET /site_phases/1.json
  def show
  end

  # GET /site_phases/new
  def new
    @site_phase = SitePhase.new
    @site_phase.periods.build
    @site_phase.typochronological_units.build
    @site_phase.ecochronological_units.build
    @site_phase.build_site
    @site_phase.build_site_type
  end

  # GET /site_phases/1/edit
  def edit
  end

  # POST /site_phases
  # POST /site_phases.json
  def create
    @site_phase = SitePhase.new(site_phase_params)

    respond_to do |format|
      if @site_phase.save
        format.html { redirect_to @site_phase, notice: 'Site phase was successfully created.' }
        format.json { render :show, status: :created, location: @site_phase }
      else
        format.html { render :new }
        format.json { render json: @site_phase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /site_phases/1
  # PATCH/PUT /site_phases/1.json
  def update
    respond_to do |format|
      if @site_phase.update(site_phase_params)
        format.html { redirect_to @site_phase, notice: 'Site phase was successfully updated.' }
        format.json { render :show, status: :ok, location: @site_phase }
      else
        format.html { render :edit }
        format.json { render json: @site_phase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /site_phases/1
  # DELETE /site_phases/1.json
  def destroy
    @site_phase.destroy
    respond_to do |format|
      format.html { redirect_to site_phases_url, notice: 'Site phase was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site_phase
      @site_phase = SitePhase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_phase_params
      params.require(:site_phase).permit(
        :id,
        :name,
        :approx_start_time,
        :approx_end_time,
        :site_id,
        :site_type_id,
        :_destroy,
        :site_attributes => [
          :id,
          :name,
          :lat,
          :lng,
          :_destroy,
          :country_id,
          :country_attributes => [
            :id,
            :name,
            :_destroy
          ],
          :fell_phases_attributes => [
            :id,
            :name,
            :start_time,
            :end_time,
            :_destroy
          ]
        ],
        :site_type_attributes => [
          :id,
          :name,
          :description,
          :_destroy
        ],
        :periods_attributes => [
          :id,
          :name,
          :approx_start_time,
          :approx_end_time,
          :_destroy
        ],
        :typochronological_units_attributes => [
            :id,
            :name,
            :approx_start_time,
            :approx_end_time,
            :_destroy
        ],
        :ecochronological_units_attributes => [
            :id,
            :name,
            :approx_start_time,
            :approx_end_time,
            :_destroy
        ]
      )
    end
end
