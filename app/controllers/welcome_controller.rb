class WelcomeController < ApplicationController
  def index
  end
  def index
    #@selected_measurements = Site.where("lat > ?", 5).all
		@selected_measurements = Site.where(name: params[:query_site_name]).all
  end 
end
