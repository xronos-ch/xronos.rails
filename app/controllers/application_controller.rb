class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/json' }
  
  # access management error handling (messages)
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { render :status => 401, :json => {:success => false, :errors => [exception.message]} }
      format.html { redirect_to request.referrer, alert: exception.message}
      format.js   { render nothing: true, status: :not_found }
    end
  end
  
  def info_for_paper_trail
    { whodunnit_user_email: current_user.email } if user_signed_in?
  end

  protected
  
  def user_for_paper_trail
    current_user.id if user_signed_in?
  end

  # default_form_builder FormHelper::BS5FormBuilder
    
end
