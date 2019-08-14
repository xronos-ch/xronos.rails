class DataController < ApplicationController
  autocomplete :site, :name, :full => true
  autocomplete :site_type, :name, :full => true
  autocomplete :country, :name, :full => true
  autocomplete :material, :name, :full => true

  def activate_right_window
    session[:right_window_active] = true
  end

  def deactivate_right_window
    session[:right_window_active] = false
  end

  def activate_left_window
    session[:left_window_active] = true
  end

  def deactivate_left_window
    session[:left_window_active] = false
  end

  def extend_left_window
    session[:left_window_big] = true
  end

  def reduce_left_window
    session[:left_window_big] = false
  end

  def reset_filter_session_variable
    session[:query_labnr] = nil
    session[:query_site_name] = nil
    session[:query_site_type] = nil
    session[:query_country] = nil
    session[:query_feature] = nil
    session[:query_material] = nil
    session[:query_species] = nil
    session[:spatial_lasso_selection] = nil
    redirect_to :root
  end

  def index

    #### update session ####

    # labnr
    if params.has_key?(:query_labnr)
      session[:query_labnr] = params[:query_labnr]
    end
    if params.has_key?(:query_labnr) and params[:query_labnr].empty?
      session[:query_labnr] = nil
    end

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

    # manual table manual_table_selection
    if params[:manual_table_selection].present?
      manual_table_selection = Array.new;
      unless params[:manual_table_selection].nil?
        manual_table_selection = JSON.parse(params[:manual_table_selection]);
      end
      session[:manual_table_selection] = manual_table_selection
    end

    if params[:turn_off_manual_table_selection].present?
      session[:manual_table_selection] = nil;
    end



    ##### select data #####

    # general dataset preparation
    @all_measurements = Measurement.left_joins( :c14_measurement, :references, :lab, sample: {arch_object: [{site_phase: [:site_type, {site: [:country, :fell_phases]}, :periods, :typochronological_units, :ecochronological_units]}, {on_site_object_position: :feature_type}, :material, :species]} ).select(
      "
      arch_objects.id as arch_object_id,
      measurements.id as measurement_id,
      measurements.labnr as labnr,
      c14_measurements.id as c14_measurement_id,
      c14_measurements.bp as bp,
      c14_measurements.std as std,
      c14_measurements.cal_bp as cal_bp,
      c14_measurements.cal_std as cal_std,
      c14_measurements.delta_c13 as delta_c13,
      labs.id as lab_id,
      labs.name as lab_name,
      sites.id as site_id,
      sites.name as site,
      site_phases.id as site_phase_id,
      site_phases.name as site_phase,
      site_types.id as site_type_id,
      site_types.name as site_type,
      on_site_object_positions.id as on_site_object_position_id,
      on_site_object_positions.feature as feature,
      feature_types.id as feature_type_id,
      feature_types.name as feature_type,
      group_concat(distinct periods.name) as periods_names,
      group_concat(distinct typochronological_units.name) as typochronological_units_names,
      group_concat(distinct ecochronological_units.name) as ecochronological_units_names,
      materials.id as material_id,
      materials.name as material,
      species.id as species_id,
      species.name as species,
      countries.id as country_id,
      countries.name as country,
      sites.lat as lat,
      sites.lng as lng,
      `references`.id as reference_id,
       group_concat(distinct `references`.short_ref) as references_short_refs
      "
    ).group("measurements.id").all

    # group_concat has to be replaced with string_agg for postgres in production

    @selected_measurements = @all_measurements

    # labnr
    unless session[:query_labnr].nil?
      @selected_measurements = @selected_measurements.where(
          "measurements.labnr LIKE ?", session[:query_labnr]
      ).all
    end

    # site name
    unless session[:query_site_name].nil?
      @selected_measurements = @selected_measurements.where(
        "sites.name IN (?)", session[:query_site_name].split(', ')
      ).all
    end

    # site type
    unless session[:query_site_type].nil?
      @selected_measurements = @selected_measurements.where(
        "site_types.name IN (?)", session[:query_site_type].split(', ')
      ).all
    end

    # country
    unless session[:query_country].nil?
      @selected_measurements = @selected_measurements.where(
          "countries.name IN (?)", session[:query_country].split(', ')
      ).all
    end

    # feature
    unless session[:query_feature].nil?
      @selected_measurements = @selected_measurements.where(
          "on_site_object_positions.feature LIKE ?", session[:query_feature]
      ).all
    end

    # material
    unless session[:query_material].nil?
      @selected_measurements = @selected_measurements.where(
          "materials.name IN (?)", session[:query_material].split(', ')
      ).all
    end

    # species
    unless session[:query_species].nil?
      @selected_measurements = @selected_measurements.where(
          "species.name LIKE ?", session[:query_species]
      ).all
    end

    # lasso
    unless session[:spatial_lasso_selection].nil?
       @selected_measurements = @selected_measurements.where(
          "sites.id IN (?)", session[:spatial_lasso_selection]
       ).all
    end

    # manual table selection
    unless session[:manual_table_selection].nil?
       @selected_measurements = @selected_measurements.where(
          "measurements.id IN (?)", session[:manual_table_selection]
       ).all
    end



    #### provide data ####
    # https://github.com/jbox-web/ajax-datatables-rails/issues/246
    params["columns"] ||= { "0" => {"data" => "" } }
    params["length"]  ||= -1

    # data for javascript
		gon.selected_measurements = @selected_measurements.to_json

    respond_to do |format|
      format.html
      # json data (u.a. for datatables)
      format.json { render json: SelectedMeasurementDatatable.new(
        params,
        {
          selected_measurements: @selected_measurements,
          view_context: view_context
        }
      )
      }
      # csv data for the download button
      format.csv { send_data @selected_measurements.to_csv, filename: "dates-#{Date.today}.csv" }
    end

  end

end
