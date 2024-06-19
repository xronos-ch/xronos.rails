class CalibrationsController < ApplicationController
  # GET /:section
  def new
    if params[:calibration_method] && params[:calibration_method] == "sum"
      ids = params[:ids].split(',').map(&:to_i) # Split the comma-separated string into an array of integers
      dates = C14.where(id: ids)    # Use the where method to find records with these IDs
      c14_ages = dates.pluck(:bp)
      c14_errors = dates.pluck(:std)
      @calibration = Calibrator::SumCalibration.new(c14_ages, c14_errors, "IntCal20")
    else
      @calibration = C14.find(params[:ids].split(',').map(&:to_i)).calibration
      @calibration.calibrate
    end
  end
end
