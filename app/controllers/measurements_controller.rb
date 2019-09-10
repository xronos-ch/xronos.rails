class MeasurementsController < ApplicationController
  load_and_authorize_resource

  before_action :set_measurement, only: [:show, :edit, :update, :destroy]

  # GET /measurements
  # GET /measurements.json
  def index
    @measurements = Measurement.all
  end

  # GET /measurements/1
  # GET /measurements/1.json
  def show
  end

  # GET /measurements/new
  def new
    @measurement = Measurement.new
    @measurement.references.build
    @measurement.build_lab
    @measurement.build_c14_measurement
  end

  # GET /measurements/1/edit
  def edit
  end

  # POST /measurements
  # POST /measurements.json
  def create
    @measurement = Measurement.new(measurement_params)
    @measurement.user_id = current_user.id if current_user

    respond_to do |format|
      if @measurement.save
        format.html { redirect_to @measurement, notice: 'Measurement was successfully created.' }
        format.json { render :show, status: :created, location: @measurement }
      else
        format.html { render :new }
        format.json { render json: @measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /measurements/1
  # PATCH/PUT /measurements/1.json
  def update
    respond_to do |format|
      if @measurement.update(measurement_params)
        format.html { redirect_to @measurement, notice: 'Measurement was successfully updated.' }
        format.json { render :show, status: :ok, location: @measurement }
      else
        format.html { render :edit }
        format.json { render json: @measurement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /measurements/1
  # DELETE /measurements/1.json
  def destroy
    @measurement.destroy
    respond_to do |format|
      format.html { redirect_to measurements_url, notice: 'Measurement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measurement
      @measurement = Measurement.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def measurement_params
      params.require(:measurement).permit(
        :id,
        :labnr,
        :_destroy,
        :sample_id,
        :lab_id,
        :c14_measurement_id,
        :c14_measurement_attributes => [
          :id,
          :bp,
          :std,
          :cal_bp,
          :cal_std,
          :delta_c13,
          :delta_c13_std,
          :method,
          :_destroy,
          :source_database_id,
          :source_database_attributes => [
            :id,
            :name,
            :url,
            :citation,
            :licence,
            :_destroy
          ]
        ],
        :lab_attributes => [
          :id,
          :name,
          :active,
          :_destroy
        ],
        :references_attributes => [
          :id,
          :short_ref,
          :bibtex,
          :_destroy
        ]
      )
    end
end
