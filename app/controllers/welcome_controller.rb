class WelcomeController < ApplicationController
  def index
  end
  def index
    @selected_measurements = Site.where("lat > ?", 5).all
  end 
end
