class ApplicationController < ActionController::Base

  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/json' }
  
  # access management error handling (messages)
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :status => 401, :json => {:success => false, :errors => [exception.message]} }
      format.html { redirect_to request.referrer, alert: exception.message}
      format.js   { render nothing: true, status: :not_found }
    end
  end

end
