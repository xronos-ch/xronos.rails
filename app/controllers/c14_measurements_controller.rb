class C14MeasurementsController < ApplicationController
  before_action :set_c14_measurement, only: [:show, :edit, :update, :destroy]

  # GET /c14_measurements
  # GET /c14_measurements.json
  def index
    @c14_measurements = C14Measurement.all
  end

  # GET /c14_measurements/1
  # GET /c14_measurements/1.json
  def show
  end

  # GET /c14_measurements/new
  def new
    @c14_measurement = C14Measurement.new
  end

  # GET /c14_measurements/1/edit
  def edit
  end

  # POST /c14_measurements
  # POST /c14_measurements.json
  def create
    @c14_measurement = C14Measurement.new(c14_measurement_params)

    respond_to do |format|
      if @c14_measurement.save
        format.html { redirect_to @c14_measurement, notice: 'C14 measurement was successfully created.' }
        format.json { render :show, status: :created, location: @c14_measurement }
      else
        format.html { render :new }
        format.json { render json: @c14_measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /c14_measurements/1
  # PATCH/PUT /c14_measurements/1.json
  def update
    respond_to do |format|
      if @c14_measurement.update(c14_measurement_params)
        format.html { redirect_to @c14_measurement, notice: 'C14 measurement was successfully updated.' }
        format.json { render :show, status: :ok, location: @c14_measurement }
      else
        format.html { render :edit }
        format.json { render json: @c14_measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /c14_measurements/1
  # DELETE /c14_measurements/1.json
  def destroy
    @c14_measurement.destroy
    respond_to do |format|
      format.html { redirect_to c14_measurements_url, notice: 'C14 measurement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_c14_measurement
      @c14_measurement = C14Measurement.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def c14_measurement_params
      params.require(:c14_measurement).permit(:bp, :std, :delta_c13, :delta_c13_std, :method)
    end
end
