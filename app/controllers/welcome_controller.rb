class WelcomeController < ApplicationController

  def index

    #### update session ####

    # site name
    if params[:query_site_name].present?
      session[:query_site_name] = params[:query_site_name]
    end

    # lasso
    if params[:spatial_lasso_selection].present?
      spatial_lasso_selection = Array.new;
      unless params[:spatial_lasso_selection].nil?
        spatial_lasso_selection = JSON.parse(params[:spatial_lasso_selection]);
      end
      session[:spatial_lasso_selection] = spatial_lasso_selection
    end

    if params[:turn_off_lasso].present?
      session[:spatial_lasso_selection] = nil;
    end

    ##### select data #####
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
    ).all

    unless session[:query_site_name].nil?
      @selected_measurements = @selected_measurements.where(
        "sites.name = ?", session[:query_site_name]
      ).all
    end

    unless session[:spatial_lasso_selection].nil?
       @selected_measurements = @selected_measurements.where(
        "measurements.id IN (?)", session[:spatial_lasso_selection]
       ).all
    end

    #### provide data ####
    # https://github.com/jbox-web/ajax-datatables-rails/issues/246
    params["columns"] ||= { "0" => {"data" => "" } }
    params["length"]  ||= -1

		gon.selected_measurements = @selected_measurements.to_json

    respond_to do |format|
      format.html
      format.json { render json: SelectedMeasurementDatatable.new(
        params,
        {
          selected_measurements: @selected_measurements
        }
      )
      }
    end
    
  end 

end
