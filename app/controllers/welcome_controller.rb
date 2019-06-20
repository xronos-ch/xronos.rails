class WelcomeController < ApplicationController
  def index
  end
  def index
    @selected_measurements = Measurement.joins(
      sample: {arch_object: :site}
    ).select(
      "measurements.id as measurements_id,
      measurements.labnr as measurements_labnr, 
			measurements.year as measurements_year, 
      sites.name as site_name, 
      sites.lat as site_lat, 
      sites.lng as site_lng"
    ).where(
      "name = ? OR (lat >= ? AND lat <= ?)", ##"name LIKE '%?%' OR (lat >= ? AND lat <= ?)", 
      params[:query_site_name],
      params[:query_lat_start],
      params[:query_lat_stop],
    ).all

		gon.selected_measurements = @selected_measurements.to_json
  end 
end