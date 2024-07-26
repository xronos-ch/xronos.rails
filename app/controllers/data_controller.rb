class DataController < ApplicationController
  include Pagy::Backend

  def turn_off_lasso
    session[:spatial_lasso_selection] = nil
    redirect_to request.env["HTTP_REFERER"]#:action => 'map'
  end
  
  def reset_manual_table_selection
    session[:manual_table_selection] = nil
    redirect_to request.env["HTTP_REFERER"]#:action => 'index'
  end

  def index
    @data = Data.new(filter_params, select_params)
    @raw_filter_params = filter_params
    logger.debug { "Parsed filters: #{@data.filters.inspect}" }
    @sites = @data.xrons.select("sites.id", "sites.lng", "sites.lat", "sites.name").distinct
    
    respond_to do |format|
      format.html { 
        @pagy, @xrons = pagy(@data.xrons)
        render layout: "full_page" 
      }
      format.json { render json: @data }
      format.geojson { 
      render json: Site.connection.exec_query(Site.select("json_agg(geojson) AS measurements").from("(select jsonb_build_object(
    'type', 'Feature',
    'geometry', jsonb_build_object(
        'type', 'Point',
        'coordinates', jsonb_build_array(lng, lat)
    ),
    'properties', jsonb_build_object(
        'name', name,
        'id', id
    )
) AS geojson from (" + @sites.to_sql+ ") AS subquery1) AS subquery2").to_sql)[0]['measurements'], adapter: nil, serializer: nil        
      }
      format.csv {
        query = "COPY (SELECT * FROM data_views WHERE id IN (" + @data.xrons.pluck(:id).join(', ').to_s + ") ) TO STDOUT WITH CSV HEADER"
        
        connection = ActiveRecord::Base.connection.raw_connection
            csv_data = ""

            connection.copy_data(query) do
              while row = connection.get_copy_data
                csv_data << row
              end
            end

            render plain: csv_data, content_type: 'text/csv', filename: "data_#{Date.today}.csv"
      }
    end
  end

  private

  def filter_params
    # DEFINE PERMITTED FILTERS
    # `:name` -> only one value allowed
    # `name: []` -> only array of values allowed
    params.fetch(:filter, {}).permit(
      {c14s: [
        :lab_identifier,
        {lab_identifier: []},
        {bp: []},
        {cal_bp: []}
      ]},
      {c14_labs: [
        :name,
        {name: []}
      ]},
      {contexts: [
        :name,
        {name: []}
      ]},
      {materials: [
        :name,
        {name: []}
      ]},
      {taxons: [
        :name,
        {name: []}
      ]},
      {typos: [
        :name,
        {name: []}
      ]},
      {references: [
        :short_ref,
        {short_ref: []},
      ]},
      {sites: [
        :name,
        {name: []},
        :country_code,
        {country_code: []},
        {lat: []},
        {lng: []}
      ]},
      {site_types: [
        :name,
        {name: []}
      ]}
    )
  end

  # TODO: is this safe???
  def select_params
    params.fetch(:select, {})
  end

end
