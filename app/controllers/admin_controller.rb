class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :add_admin_breadcrumb

  layout "admin"

  def index
  end

  private

  def add_admin_breadcrumb
    breadcrumbs.add "Admin", admin_path
  end
end
