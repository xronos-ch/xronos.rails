class DendroMeasurementsController < ApplicationController
  load_and_authorize_resource

  before_action :set_dendro_measurement, only: [:show, :edit, :update, :destroy]

  # GET /dendro_measurements
  # GET /dendro_measurements.json
  def index
    @dendro_measurements = DendroMeasurement.all
  end

  # GET /dendro_measurements/1
  # GET /dendro_measurements/1.json
  def show
  end

  # GET /dendro_measurements/new
  def new
    @dendro_measurement = DendroMeasurement.new
  end

  # GET /dendro_measurements/1/edit
  def edit
  end

  # POST /dendro_measurements
  # POST /dendro_measurements.json
  def create
    @dendro_measurement = DendroMeasurement.new(dendro_measurement_params)

    respond_to do |format|
      if @dendro_measurement.save
        format.html { redirect_to @dendro_measurement, notice: 'Dendro measurement was successfully created.' }
        format.json { render :show, status: :created, location: @dendro_measurement }
      else
        format.html { render :new }
        format.json { render json: @dendro_measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dendro_measurements/1
  # PATCH/PUT /dendro_measurements/1.json
  def update
    respond_to do |format|
      if @dendro_measurement.update(dendro_measurement_params)
        format.html { redirect_to @dendro_measurement, notice: 'Dendro measurement was successfully updated.' }
        format.json { render :show, status: :ok, location: @dendro_measurement }
      else
        format.html { render :edit }
        format.json { render json: @dendro_measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dendro_measurements/1
  # DELETE /dendro_measurements/1.json
  def destroy
    @dendro_measurement.destroy
    respond_to do |format|
      format.html { redirect_to dendro_measurements_url, notice: 'Dendro measurement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dendro_measurement
      @dendro_measurement = DendroMeasurement.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dendro_measurement_params
      params.require(:dendro_measurement).permit(:age, :start_age_deviation, :end_age_deviation, :dating_quality_estimation_category)
    end
end
