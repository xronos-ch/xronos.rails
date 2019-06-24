class WelcomeController < ApplicationController
  def index
  end
  def index
    
		spatial_lasso_selection = Array.new;
		unless params[:spatial_lasso_selection].nil?
			spatial_lasso_selection = JSON.parse(params[:spatial_lasso_selection]);
		end   

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
      "measurements_id IN (?) OR name = ? OR (lat >= ? AND lat <= ?)", ##"name LIKE '%?%' OR (lat >= ? AND lat <= ?)", 
			spatial_lasso_selection,      
			params[:query_site_name],
      params[:query_lat_start],
      params[:query_lat_stop],
    ).all

		gon.selected_measurements = @selected_measurements.to_json
  end 
end