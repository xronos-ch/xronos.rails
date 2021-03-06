class ApplicationController < ActionController::Base

  # access management error handling (messages)
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render nothing: true, status: :not_found }
      format.html { redirect_to request.referrer, alert: exception.message}
      format.js   { render nothing: true, status: :not_found }
    end
  end

end
