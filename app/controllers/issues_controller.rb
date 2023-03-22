class IssuesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  layout "curate"

  def index
  end
end
