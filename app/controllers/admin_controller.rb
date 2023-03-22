class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :add_admin_breadcrumb

  layout "admin"

  private

  def add_admin_breadcrumb
    breadcrumbs.add "Admin"
  end
end
