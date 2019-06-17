class WelcomeController < ApplicationController
  def index
  end
  def index
		@selected_measurements = Site.where(
      "name = ? OR (lat >= ? AND lat <= ?)",
      #"name LIKE '%?%' OR (lat >= ? AND lat <= ?)", 
      params[:query_site_name],
      params[:query_lat_start],
      params[:query_lat_stop],
    ).all
  end 
end
