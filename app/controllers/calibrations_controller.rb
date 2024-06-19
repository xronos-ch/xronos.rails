class CalibrationsController < ApplicationController
  # GET /:section
  def new
      @calibration = C14.find(params[:ids]).calibration
      @calibration.calibrate
  end
end
