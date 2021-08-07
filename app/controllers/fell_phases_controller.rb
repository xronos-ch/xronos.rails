class FellPhasesController < ApplicationController
  load_and_authorize_resource

  before_action :set_fell_phase, only: [:show, :edit, :update, :destroy]

  # GET /fell_phases
  # GET /fell_phases.json
  def index
    @fell_phases = FellPhase.all
  end

  # GET /fell_phases/1
  # GET /fell_phases/1.json
  def show
  end

  # GET /fell_phases/new
  def new
    @fell_phase = FellPhase.new
    @fell_phase.references.build
  end

  # GET /fell_phases/1/edit
  def edit
  end

  # POST /fell_phases
  # POST /fell_phases.json
  def create
    @fell_phase = FellPhase.new(fell_phase_params)

    respond_to do |format|
      if @fell_phase.save
        format.html { redirect_to @fell_phase, notice: 'Fell phase was successfully created.' }
        format.json { render :show, status: :created, location: @fell_phase }
      else
        format.html { render :new }
        format.json { render json: @fell_phase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fell_phases/1
  # PATCH/PUT /fell_phases/1.json
  def update
    respond_to do |format|
      if @fell_phase.update(fell_phase_params)
        format.html { redirect_to @fell_phase, notice: 'Fell phase was successfully updated.' }
        format.json { render :show, status: :ok, location: @fell_phase }
      else
        format.html { render :edit }
        format.json { render json: @fell_phase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fell_phases/1
  # DELETE /fell_phases/1.json
  def destroy
    @fell_phase.destroy
    respond_to do |format|
      format.html { redirect_to fell_phases_url, notice: 'Fell phase was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fell_phase
      @fell_phase = FellPhase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fell_phase_params
      params.require(:fell_phase).permit(
        :id,
        :name,
        :start_time,
        :end_time,
        :site_id,
        :_destroy,
        :references_attributes => [
          :id,
          :short_ref,
          :bibtex,
          :_destroy
        ]
      )
    end
end
