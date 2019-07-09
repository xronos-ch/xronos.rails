class DataController < ApplicationController

  def index

    #### update session ####
    # site name
    if params.has_key?(:query_site_name)
      session[:query_site_name] = params[:query_site_name]
    end
    if params.has_key?(:query_site_name) and params[:query_site_name].empty?
      session[:query_site_name] = nil
    end

    # site type
    if params.has_key?(:query_site_type)
      session[:query_site_type] = params[:query_site_type]
    end
    if params.has_key?(:query_site_type) and params[:query_site_type].empty?
      session[:query_site_type] = nil
    end

    # country
    if params.has_key?(:query_country)
      session[:query_country] = params[:query_country]
    end
    if params.has_key?(:query_country) and params[:query_country].empty?
      session[:query_country] = nil
    end

    # feature
    if params.has_key?(:query_feature)
      session[:query_feature] = params[:query_feature]
    end
    if params.has_key?(:query_feature) and params[:query_feature].empty?
      session[:query_feature] = nil
    end

    # material
    if params.has_key?(:query_material)
      session[:query_material] = params[:query_material]
    end
    if params.has_key?(:query_material) and params[:query_material].empty?
      session[:query_material] = nil
    end

    # species
    if params.has_key?(:query_species)
      session[:query_species] = params[:query_species]
    end
    if params.has_key?(:query_species) and params[:query_species].empty?
      session[:query_species] = nil
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
		# general dataset preparation
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

    # site name
    unless session[:query_site_name].nil?
      @selected_measurements = @selected_measurements.where(
        "sites.name = ?", session[:query_site_name]
      ).all
    end

    # site type
    unless session[:query_site_type].nil?
      @selected_measurements = @selected_measurements.where(
        "site_types.name = ?", session[:query_site_type]
      ).all
    end

    # country
    unless session[:query_country].nil?
      @selected_measurements = @selected_measurements.where(
          "countries.name = ?", session[:query_country]
      ).all
    end

    # feature
    unless session[:query_feature].nil?
      @selected_measurements = @selected_measurements.where(
          "on_site_object_positions.feature = ?", session[:query_feature]
      ).all
    end

    # material
    unless session[:query_material].nil?
      @selected_measurements = @selected_measurements.where(
          "materials.name = ?", session[:query_material]
      ).all
    end

    # species
    unless session[:query_species].nil?
      @selected_measurements = @selected_measurements.where(
          "(species.family || ' ' || species.genus || ' ' || species.species  || ' ' || species.subspecies) = ?", session[:query_species]
      ).all
    end

    # lasso
    unless session[:spatial_lasso_selection].nil?
       @selected_measurements = @selected_measurements.where(
        "measurements.id IN (?)", session[:spatial_lasso_selection]
       ).all
    end



    #### provide data ####
    # https://github.com/jbox-web/ajax-datatables-rails/issues/246
    params["columns"] ||= { "0" => {"data" => "" } }
    params["length"]  ||= -1

    # data for javascript
		gon.selected_measurements = @selected_measurements.to_json

    # json data (u.a. for datatables)
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
