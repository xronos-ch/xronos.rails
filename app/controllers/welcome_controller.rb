class WelcomeController < ApplicationController
  def index
  end
  def index
		#@selected_measurements = Site.where(
      #"name = ? OR (lat >= ? AND lat <= ?)",
      ##"name LIKE '%?%' OR (lat >= ? AND lat <= ?)", 
      #params[:query_site_name],
      #params[:query_lat_start],
      #params[:query_lat_stop],
    #).all
    @selected_measurements = Measurement.joins(
      sample: {arch_object: :site}
    ).select(
      "measurements.year, 
      measurements.labnr, 
      sites.name, 
      sites.lat, 
      sites.lng"
    ).all
  end 
end