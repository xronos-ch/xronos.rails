class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?
  before_action :set_paper_trail_whodunnit

  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Redirect to last page on sign in
  # https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

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
    
  private

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

end
