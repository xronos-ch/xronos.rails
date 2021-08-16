class MeasurementStatesController < ApplicationController
  before_action :set_measurement_state, only: %i[ show edit update destroy ]

  # GET /measurement_states or /measurement_states.json
  def index
    @measurement_states = MeasurementState.all
  end

  # GET /measurement_states/1 or /measurement_states/1.json
  def show
  end

  # GET /measurement_states/new
  def new
    @measurement_state = MeasurementState.new
  end

  # GET /measurement_states/1/edit
  def edit
  end

  # POST /measurement_states or /measurement_states.json
  def create
    @measurement_state = MeasurementState.new(measurement_state_params)

    respond_to do |format|
      if @measurement_state.save
        format.html { redirect_to @measurement_state, notice: "Measurement state was successfully created." }
        format.json { render :show, status: :created, location: @measurement_state }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @measurement_state.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /measurement_states/1 or /measurement_states/1.json
  def update
    respond_to do |format|
      if @measurement_state.update(measurement_state_params)
        format.html { redirect_to @measurement_state, notice: "Measurement state was successfully updated." }
        format.json { render :show, status: :ok, location: @measurement_state }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @measurement_state.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /measurement_states/1 or /measurement_states/1.json
  def destroy
    @measurement_state.destroy
    respond_to do |format|
      format.html { redirect_to measurement_states_url, notice: "Measurement state was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measurement_state
      @measurement_state = MeasurementState.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def measurement_state_params
      params.require(:measurement_state).permit(:name, :description)
    end
end
