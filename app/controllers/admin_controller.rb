class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :add_admin_breadcrumb

  layout "admin"

  def index
  end

  private

  def add_admin_breadcrumb
    unless request.controller_class.name.split('::').first == "MissionControl" then
      breadcrumbs.add "Admin", admin_path 
    end
  end
end
