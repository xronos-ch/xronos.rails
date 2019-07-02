class WelcomeController < ApplicationController

  def index

    #### update session ####
    if params[:query_lat_start].present?
      session[:query_lat_start] = params[:query_lat_start]
    end
    if params[:query_lat_stop].present?
      session[:query_lat_stop] = params[:query_lat_stop]
    end

    if params[:spatial_lasso_selection].present?
      spatial_lasso_selection = Array.new;
      unless params[:spatial_lasso_selection].nil?
        spatial_lasso_selection = JSON.parse(params[:spatial_lasso_selection]);
      end
      session[:spatial_lasso_selection] = spatial_lasso_selection
    end

    puts("#####" + params[:spatial_lasso_selection].to_s + "#####")
    puts("#####" + session[:spatial_lasso_selection].to_s + "#####")
    puts("#####" + session[:spatial_lasso_selection].map{|x| x.to_i}.to_s + "#####")

		@selected_measurements = Measurement.joins(
      sample: {arch_object: [{site: [:site_type, :country]}, {on_site_object_position: :feature_type}, :material, :species]}
    ).select(
      "
      measurements.id as measurement_id,
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
      session[:query_lat_start],
      session[:query_lat_stop],
    ).all

    unless params[:spatial_lasso_selection].nil?
       @selected_measurements = @selected_measurements.where(
        "measurement_id IN (?)", session[:spatial_lasso_selection]
      ).all
    end

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
