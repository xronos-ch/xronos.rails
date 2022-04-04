class DataController < ApplicationController

  #### autocomplete initialisation ####
  autocomplete :source_database, :name, :full => true
  autocomplete :site, :name, :full => true
  autocomplete :site_type, :name, :full => true
  autocomplete :country, :name, :full => true
  autocomplete :material, :name, :full => true

  #### filter buttons ####
  def reset_filter_session_variable
    referrer_url = URI.parse(request.referrer) rescue URI.parse("/")
    referrer_url.query = Rack::Utils.parse_nested_query(referrer_url.query).delete_if { |key, value| key.to_s.match(/^query_.+/) }.to_query
    
    session.keys.each do |key|
      if key.to_s.match(/^query_.+/)
        session[key] = nil
      end
    end
    session[:spatial_lasso_selection] = nil
    redirect_to referrer_url.to_s
  end
  
  def turn_off_lasso
    session[:spatial_lasso_selection] = nil
    redirect_to request.env["HTTP_REFERER"]#:action => 'map'
  end
  
  def reset_manual_table_selection
    session[:manual_table_selection] = nil
    redirect_to request.env["HTTP_REFERER"]#:action => 'index'
  end

  def index
  	get_data
  end
  
  def map
  	get_data
  end

  def table
  	get_data
  end
  
  private

  def get_data

    #### update session ####

    # uncal age
    if params.has_key?(:query_uncal_age_start)
      session[:query_uncal_age_start] = params[:query_uncal_age_start].to_i
    end
    if params.has_key?(:query_uncal_age_start) and params[:query_uncal_age_start].empty?
      session[:query_uncal_age_start] = nil
    end
    if params.has_key?(:query_uncal_age_stop)
      session[:query_uncal_age_stop] = params[:query_uncal_age_stop].to_i
    end
    if params.has_key?(:query_uncal_age_stop) and params[:query_uncal_age_stop].empty?
      session[:query_uncal_age_stop] = nil
    end
    unless session[:query_uncal_age_start].nil?
      gon.uncal_age_start = session[:query_uncal_age_start]
    end

    unless session[:query_uncal_age_stop].nil?
      gon.uncal_age_stop = session[:query_uncal_age_stop]
    end

    # cal age
    if params.has_key?(:query_cal_age_start)
      session[:query_cal_age_start] = params[:query_cal_age_start].to_i
    end
    if params.has_key?(:query_cal_age_start) and params[:query_cal_age_start].empty?
      session[:query_cal_age_start] = nil
    end
    if params.has_key?(:query_cal_age_stop)
      session[:query_cal_age_stop] = params[:query_cal_age_stop].to_i
    end
    if params.has_key?(:query_cal_age_stop) and params[:query_cal_age_stop].empty?
      session[:query_cal_age_stop] = nil
    end
    unless session[:query_cal_age_start].nil?
      gon.cal_age_start = session[:query_cal_age_start]
    end
    unless session[:query_cal_age_stop].nil?
      gon.cal_age_stop = session[:query_cal_age_stop]
    end

    # source_database name
    if params.has_key?(:query_source_database)
      session[:query_source_database] = params[:query_source_database]
    end
    if params.has_key?(:query_source_database) and params[:query_source_database].empty?
      session[:query_source_database] = nil
    end

    # lab_identifier
    if params.has_key?(:query_lab_identifier)
      session[:query_lab_identifier] = params[:query_lab_identifier]
    end
    if params.has_key?(:query_lab_identifier) and params[:query_lab_identifier].empty?
      session[:query_lab_identifier] = nil
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

    # material
    if params.has_key?(:query_material)
      session[:query_material] = params[:query_material]
    end
    if params.has_key?(:query_material) and params[:query_material].empty?
      session[:query_material] = nil
    end

    # taxon
    if params.has_key?(:query_taxon)
      session[:query_taxon] = params[:query_taxon]
    end
    if params.has_key?(:query_taxon) and params[:query_taxon].empty?
      session[:query_taxon] = nil
    end

    # country
    if params.has_key?(:query_country)
      session[:query_country] = params[:query_country]
    end
    if params.has_key?(:query_country) and params[:query_country].empty?
      session[:query_country] = nil
    end

    # reference
    if params.has_key?(:query_reference)
      session[:query_reference] = params[:query_reference]
    end
    if params.has_key?(:query_reference) and params[:query_reference].empty?
      session[:query_reference] = nil
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
    @data ||= C14.includes(
      :source_database,
      :c14_lab,
      #sample: {arch_object: [{site_phase: [{site: :country}, :periods, :typochronological_units, :ecochronological_units]}, {on_site_object_position: :feature_type}, :material, :species]}
      sample: [{context: {site: :country}}, :material, :taxon]
    )

    # uncal age
    unless session[:query_uncal_age_start].nil?
      @data = @data.where(
        c14s: {:bp => (session[:query_uncal_age_stop]..session[:query_uncal_age_start])}
      )
    end

    # cal age
    unless session[:query_cal_age_start].nil?
      @data = @data.where(
        c14s: {:cal_bp => (session[:query_cal_age_stop]..session[:query_cal_age_start])}
      )
    end

    # source_database name
    unless session[:query_source_database].nil?
      @data = @data.where(
        c14s: {source_databases: {:name => session[:query_source_database].split('|')}}
      )
    end

    # lab_identifier
    unless session[:query_lab_identifier].nil?
      @data = @data.where(
        lab_identifier: params[:query_lab_identifier].split('|')
      )
    end

    # site name
    unless session[:query_site].nil?
      @data = @data.where(
        sample: {context: {site: {:name => session[:query_site].split('|')}}}
      )
    end

    # site type
    unless session[:query_site_type].nil?
      @data = @data.where(
        sample: {context: {site: {site_types: {name: session[:query_site_type].split('|')}}}}
      )
    end

    # material
    unless session[:query_material].nil?
      @data = @data.where(
        sample: {material: {name: session[:query_material].split('|')}}
      )
    end

    # taxon
    unless session[:query_taxon].nil?
      @data = @data.where(
        sample: {taxon: {name: session[:query_taxon].split('|')}}
      )
    end

    # country
    unless session[:query_country].nil?
      @data = @data.where(
        sample: {context: {site: {countries: {name: session[:query_country].split('|')}}}}
      )
    end

    # lasso
    unless session[:spatial_lasso_selection].nil?
       @data = @data.where(
         sample: {context: {sites: {id: session[:spatial_lasso_selection].split('|')}}}
       )
    end

    # manual table selection
    unless session[:manual_table_selection].nil?
       @data = @data.where(
          id: session[:manual_table_selection]
       )
    end
    
    #### provide data ####

    respond_to do |format|
      format.html {
      		# json data (for map)
		sample_ids = @data.distinct.pluck(:id)
		gon.selected_sites = Site.distinct.joins(contexts: :samples).where(samples: {id: sample_ids}).where.not(lat: nil).where.not(lng: nil).select(:id, :name, :lat, :lng)
		gon.selected_sites = Oj.dump(gon.selected_sites)
      }
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
          recordsFiltered: @data.size,
          recordsTotal: C14.count
        }
      }
      # csv data for the download button
      format.csv { send_data @data.to_csv, filename: "dates-#{Date.today}.csv" }
    end

  end

end
