class WelcomeController < ApplicationController

  def index

    #### update session ####
    if params[:query_lat_start].present?
      session[:query_lat_start] = params[:query_lat_start]
    end
    if params[:query_lat_stop].present?
      session[:query_lat_stop] = params[:query_lat_stop]
    end

    spatial_lasso_selection = Array.new;
		unless params[:spatial_lasso_selection].nil?
			spatial_lasso_selection = JSON.parse(params[:spatial_lasso_selection]);
		end   

    puts("#####" + params[:query_lat_start].to_s + "#####")
    #session[:query_lat_start] = params[:query_lat_start]
    puts("#####" + session[:query_lat_start].to_s + "#####")

		@selected_measurements = Measurement.joins(
      sample: {arch_object: [{site: [:site_type, :country]}, {on_site_object_position: :feature_type}, :material, :species]}
    ).select(
      "
      measurements.labnr as labnr,
      measurements.year as year,
      sites.name as site,
      site_types.name as site_type,
      sites.lat as lat,
      sites.lng as lng,
      countries.name as country,
      on_site_object_positions.feature as feature,
      materials.name as material,
      (species.family || ' ' || species.genus || ' ' || species.species  || ' ' || species.subspecies) as species
      "
    ).where(
      "lat >= ? AND lat <= ?",
			#params[:query_site_name],
      session[:query_lat_start],
      session[:query_lat_stop],
    ).all

		gon.selected_measurements = @selected_measurements.to_json

    respond_to do |format|
      format.html
      format.json { render json: SelectedMeasurementDatatable.new(
        params,
        {
          selected_measurements: @selected_measurements
        }
      ) }
    end
    
  end 

end
