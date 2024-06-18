class CalibrationsController < ApplicationController
  # GET /:section
  def new
      @calibration = C14.first.calibration
      @calibration.calibrate
  end
end
