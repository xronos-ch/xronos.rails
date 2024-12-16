class XronosDataController < ApplicationController
  include Pagy::Backend

  before_action :set_data, only: [:index]

  def turn_off_lasso
    reset_session_key(:spatial_lasso_selection)
  end

  def reset_manual_table_selection
    reset_session_key(:manual_table_selection)
  end

  def index
    @raw_filter_params = filter_params
    logger.debug { "Parsed filters: #{@data.filters.inspect}" }

    respond_to do |format|
      format.html { render_index_html }
      format.json { render json: @data.xrons }
      format.geojson { render_geojson }
      format.csv { render_csv }
    end
  end

  private

  def set_data
    # Initialize data for C14 and Dendro, applying filters and selections
    @c14_data = XronosData.new(filter_params, select_params, :c14)
    @dendro_data = XronosData.new(filter_params, select_params, :dendro)
  
    # Assign the default data view to @data (e.g., C14 by default)
    @data = @c14_data
  
    # Fetch site data from both C14 and Dendro queries
    c14_sites = @c14_data.xrons
                         .joins("LEFT JOIN sites ON sites.id = contexts.site_id")
                         .select("sites.id AS site_id, sites.lng, sites.lat, sites.name AS site_name")
                         .distinct

    dendro_sites = @dendro_data.xrons
                               .joins("LEFT JOIN sites ON sites.id = contexts.site_id")
                               .select("sites.id AS site_id, sites.lng, sites.lat, sites.name AS site_name")
                               .distinct
  
    # Combine site queries and remove duplicates
    combined_sites_query = "(#{c14_sites.to_sql} UNION #{dendro_sites.to_sql}) AS combined_sites"
    @sites = Site.from(combined_sites_query).select("site_id, lng, lat, site_name").distinct
  end

  def reset_session_key(key)
    session[key] = nil
    redirect_back(fallback_location: root_path)
  end

  def filter_params
    params.fetch(:filter, {}).permit(
      c14s: [
        :lab_identifier, { lab_identifier: [] }, { bp: [] }
      ],
      cals: [
        :tpq, { tpq: [] }, :taq, { taq: [] }
      ],
      c14_labs: [
        :name, { name: [] }
      ],
      contexts: [
        :name, { name: [] }
      ],
      materials: [
        :name, { name: [] }
      ],
      taxons: [
        :name, { name: [] }
      ],
      typos: [
        :name, { name: [] }
      ],
      references: [
        :short_ref, { short_ref: [] }
      ],
      sites: [
        :name, { name: [] }, :country_code, { country_code: [] }, 
        { lat: [] }, { lng: [] }
      ],
      site_types: [
        :name, { name: [] }
      ]
    )
  end

  def select_params
    params.fetch(:select, {})
  end

  def render_index_html
    @pagy, @xrons = pagy(@data.xrons)
    render layout: "full_page"
  end

  def render_geojson
    geojson_query = Site.select("json_agg(geojson) AS measurements")
                        .from(build_geojson_subquery)
    render json: Site.connection.exec_query(geojson_query.to_sql)[0]['measurements'],
           adapter: nil, serializer: nil
  end

  def build_geojson_subquery
    <<~SQL
      (SELECT jsonb_build_object(
          'type', 'Feature',
          'geometry', jsonb_build_object(
              'type', 'Point',
              'coordinates', jsonb_build_array(lng, lat)
          ),
          'properties', jsonb_build_object(
              'name', site_name,
              'id', site_id
          )
      ) AS geojson FROM (#{@sites.to_sql}) AS subquery1) AS subquery2
    SQL
  end

  def render_csv
    query = <<~SQL
      COPY (
        SELECT * FROM data_views WHERE id IN (#{@data.xrons.pluck(:id).join(', ')})
      ) TO STDOUT WITH CSV HEADER
    SQL

    csv_data = fetch_csv_data(query)
    render plain: csv_data, content_type: 'text/csv', filename: "data_#{Date.today}.csv"
  end

  def fetch_csv_data(query)
    connection = ActiveRecord::Base.connection.raw_connection
    csv_data = ""

    connection.copy_data(query) do
      while (row = connection.get_copy_data)
        csv_data << row
      end
    end

    csv_data
  end
end