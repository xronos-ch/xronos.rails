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

    # Select data based on the 'type' parameter
    export_data = case params[:type]
           when "c14" then @c14_data.xrons
           when "dendro" then @dendro_data.xrons
           else @data.xrons
           end
           
    respond_to do |format|
      format.html { render_index_html }
      format.json { render json: export_data }
      format.geojson { render_geojson }
      format.csv { render_csv }
    end
  end

  private

  def set_data
    # Determine the requested type (C14 or Dendro) and adjust filters
    type_filter = filter_params[:type]&.map(&:downcase) || %w[c14 dendro]

    # Separate filters based on type
    if type_filter.include?("c14")
      @c14_filter_params = filter_params.except(:type)
      @c14_data = XronosData.new(@c14_filter_params, select_params, :c14)
    else
      @c14_data = nil
    end

    if type_filter.include?("dendro")
      @dendro_filter_params = filter_params.except(:type, :c14s, :cals)
      @dendro_data = XronosData.new(@dendro_filter_params, select_params, :dendro)
    else
      @dendro_data = nil
    end

    # Set @data to the primary dataset, or a placeholder with filters
    if @c14_data
      @data = @c14_data
    elsif @dendro_data
      @data = @dendro_data
    else
      @data = XronosData.new(filter_params, select_params)
    end

    # Calculate total records and initialize sites
    @n_data = (@c14_data&.xrons&.count || 0) + (@dendro_data&.xrons&.count || 0)
    @total_data = (@c14_data&.everything&.count || 0) + (@dendro_data&.everything&.count || 0)

    # Fetch site data based on the type filter
    c14_sites = @c14_data&.xrons&.joins("LEFT JOIN sites ON sites.id = contexts.site_id")
                         &.select("sites.id AS site_id, sites.lng, sites.lat, sites.name AS site_name")
                         &.distinct

    dendro_sites = @dendro_data&.xrons&.joins("LEFT JOIN sites ON sites.id = contexts.site_id")
                               &.select("sites.id AS site_id, sites.lng, sites.lat, sites.name AS site_name")
                               &.distinct

    if c14_sites && dendro_sites
      combined_sites_query = "((#{c14_sites.to_sql}) UNION (#{dendro_sites.to_sql})) AS combined_sites"
      @sites = Site.from(combined_sites_query).select("site_id, lng, lat, site_name").distinct
    elsif c14_sites
      @sites = c14_sites
    elsif dendro_sites
      @sites = dendro_sites
    else
      @sites = Site.none
    end
  end

  def reset_session_key(key)
    session[key] = nil
    redirect_back(fallback_location: root_path)
  end

  def filter_params
    return {} unless params[:filter].present? # Return an empty hash if :filter is nil or empty
    
    params.fetch(:filter, {}).permit(
    type: [],
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
    if @c14_data
      @c14_pagy, @c14_xrons = pagy(@c14_data.xrons)
    else
      @c14_pagy, @c14_xrons = nil, []
    end

    if @dendro_data
      @dendro_pagy, @dendro_xrons = pagy(@dendro_data.xrons)
    else
      @dendro_pagy, @dendro_xrons = nil, []
    end

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
    # Determine the query based on the 'type' parameter
    query = case params[:type]
            when "c14"
              <<~SQL
                COPY (
                  SELECT * FROM data_views WHERE id IN (#{@c14_data.xrons.pluck(:id).join(', ')})
                ) TO STDOUT WITH CSV HEADER
              SQL
            when "dendro" # Preliminary dump the dendro table, ToDo when datastructure is fixed, replace by an related mat_view
              <<~SQL
                COPY (
                  SELECT * FROM dendros WHERE id IN (#{@dendro_data.xrons.pluck(:id).join(', ')})
                ) TO STDOUT WITH CSV HEADER
              SQL
            end

    # Fetch CSV data and render it
    csv_data = fetch_csv_data(query)
    render plain: csv_data, content_type: 'text/csv', filename: "#{params[:type] || 'data'}_#{Date.today}.csv"
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