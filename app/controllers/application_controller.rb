class ApplicationController < ActionController::Base
  before_action :store_user_location!, if: :storable_location?
  before_action :set_paper_trail_whodunnit

  before_action :http_basic_authenticate
  
  after_action lambda {
    cookies.delete(Rails.application.config.session_options[:key]) unless user_signed_in?
    request.session_options[:skip] = !(user_signed_in? || devise_controller?)
  }

  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Redirect to last page on sign in
  # https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

  # Return 404 for unauthorised resources
  rescue_from CanCan::AccessDenied do |exception|
    raise ActionController::RoutingError.new('Not Found')
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

  def http_basic_authenticate
    if Rails.env.staging?
      authenticate_or_request_with_http_basic do |username, password|
        username == "2user" && password == "pass1"
      end
    end
  end

end
