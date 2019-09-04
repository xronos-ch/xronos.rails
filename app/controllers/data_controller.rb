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
    session[:query_site] = nil
    session[:query_site_type] = nil
    session[:query_country] = nil
    session[:query_feature] = nil
    session[:query_material] = nil
    session[:query_species] = nil
    session[:spatial_lasso_selection] = nil
    redirect_to :root
  end

  def turn_off_lasso
    session[:spatial_lasso_selection] = nil
    redirect_to :root
  end

  def reset_manual_table_selection
    session[:manual_table_selection] = nil
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
    if params.has_key?(:query_site)
      session[:query_site] = params[:query_site]
    end
    if params.has_key?(:query_site) and params[:query_site].empty?
      session[:query_site] = nil
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

    # manual table manual_table_selection
    if params[:manual_table_selection].present?
      manual_table_selection = Array.new;
      unless params[:manual_table_selection].nil?
        manual_table_selection = JSON.parse(params[:manual_table_selection]);
      end
      session[:manual_table_selection] = manual_table_selection
    end



    ##### select data #####

    # general dataset preparation
    @data ||= Measurement.includes(:c14_measurement, :lab, sample: {arch_object: [{site_phase: {site: :country}}, :on_site_object_position, :material, :species]})

    # labnr
    unless session[:query_labnr].nil?
      @data = @data.where(
          "measurements.labnr LIKE ?", session[:query_labnr]
      ).all
    end

    # site name
    unless session[:query_site].nil?
      @data = @data.where(
        sample: {arch_object: {site_phase: {sites: {:name => session[:query_site].split('|')}}}}
      ).all
    end

    # site type
    unless session[:query_site_type].nil?
      @data = @data.where(
        sample: {arch_object: {site_phase: {site_types: {name: session[:query_site_type].split('|')}}}}
      ).all
    end

    # country
    unless session[:query_country].nil?
      @data = @data.where(
        sample: {arch_object: {site_phase: {site: {countries: {name: session[:query_country].split('|')}}}}}
      ).all
    end

    # feature
    unless session[:query_feature].nil?
      @data = @data.where(
        sample: {arch_object: {on_site_object_positions: {feature: session[:query_feature].split('|')}}}
      ).all
    end

    # material
    unless session[:query_material].nil?
      @data = @data.where(
        sample: {arch_object: {materials: {name: session[:query_material].split('|')}}}
      ).all
    end

    # species
    unless session[:query_species].nil?
      @data = @data.where(
        sample: {arch_object: {species: {name: session[:query_species].split('|')}}}
      ).all
    end

    # lasso
    unless session[:spatial_lasso_selection].nil?
       @data = @data.where(
         sample: {arch_object: {site_phase: {sites: {id: session[:spatial_lasso_selection].split('|')}}}}
       ).all
    end

    # manual table selection
    unless session[:manual_table_selection].nil?
       @data = @data.where(
          "measurements.id IN (?)", session[:manual_table_selection]
       ).all
    end

    #### provide data ####
    # https://github.com/jbox-web/ajax-datatables-rails/issues/246
    params["columns"] ||= { "0" => {"data" => "" } }
    params["length"]  ||= -1

		# json data (for map)
		gon.selected_sites = @data.map { |measurement| measurement.sample.arch_object.site_phase}.compact.map { |measurement| measurement.site}.select { |site| site.lat != nil and site.lat != nil}.uniq.to_json

    respond_to do |format|
      format.html
      # json data (for datatables)
      format.json {
        render json: {
          data: SelectedMeasurementDatatable.new(
            params,
            {
              selected_measurements: @data,
              view_context: view_context
            }
          ).data,
          recordsFiltered: @data.length,
          recordsTotal: Measurement.count
        }
      }
      # csv data for the download button
      format.csv { send_data @data.to_csv, filename: "dates-#{Date.today}.csv" }
    end

  end

end
