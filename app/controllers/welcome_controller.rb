class WelcomeController < ApplicationController
  def index
  end
  def index
    @data = Site.all
  end 
end
