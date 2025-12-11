class XronosDataController < ApplicationController
  include Pagy::Backend

  def turn_off_lasso
    session[:spatial_lasso_selection] = nil
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def reset_manual_table_selection
    session[:manual_table_selection] = nil
    redirect_to request.env["HTTP_REFERER"]
  end

  def index
    @data              = XronosData.new(filter_params, select_params)
    @raw_filter_params = filter_params
    logger.debug { "Parsed filters: #{@data.filters.inspect}" }

    # Base relation for sites (used in map + geojson)
    sites_relation = @data.xrons
                          .select("sites.id", "sites.lng", "sites.lat", "sites.name")
                          .distinct

    # For the HTML map we want a collection to iterate on.
    # For unfiltered requests, cache that list for 10 minutes.
    @sites = if unfiltered_request?
      Rails.cache.fetch(cache_key_for("sites_collection"), expires_in: 10.minutes) do
        sites_relation.to_a
      end
    else
      sites_relation
    end

    # Keep SQL for geojson builder (always from relation, not from @sites)
    sites_sql = sites_relation.to_sql

    respond_to do |format|
      # ---------------------------
      # HTML (/data)
      # ---------------------------
      format.html do
        if unfiltered_request?
          # Unfiltered case: we only need one count,
          # and filtered == total. Cache it.
          base_relation = @data.everything.except(:select, :includes, :order)

          @total_count = @filtered_count =
            Rails.cache.fetch(cache_key_for("total_count"), expires_in: 10.minutes) do
              base_relation.distinct.count(:id)
            end
        else
          # Filtered case: we need both numbers
          filtered_relation = @data.xrons.except(:select, :includes, :order)
          total_relation    = @data.everything.except(:select, :includes, :order)

          @filtered_count = filtered_relation.distinct.count(:id)
          @total_count    = Rails.cache.fetch(cache_key_for("total_count"), expires_in: 10.minutes) do
            total_relation.distinct.count(:id)
          end
        end

        # your existing includes + pagination
        xrons_relation = @data.xrons.includes(
          sample: [
            :material,
            :taxon,
            { context: :site }
          ]
        )

        if unfiltered_request?
          @pagy, @xrons = Rails.cache.fetch(
            cache_key_for("html_page_#{params[:page] || 1}"),
            expires_in: 10.minutes
          ) do
            pagy(xrons_relation)
          end
        else
          @pagy, @xrons = pagy(xrons_relation)
        end

        render layout: "full_page"
      end

      # ---------------------------
      # JSON (/data.json)
      # ---------------------------
      format.json do
        if unfiltered_request?
          json_payload = Rails.cache.fetch(
            cache_key_for("json"),
            expires_in: 10.minutes
          ) do
            @data.as_json
          end
          render json: json_payload
        else
          render json: @data
        end
      end

      # ---------------------------
      # GEOJSON (/data.geojson)
      # ---------------------------
      format.geojson do
        geojson = if unfiltered_request?
          Rails.cache.fetch(
            cache_key_for("geojson"),
            expires_in: 10.minutes
          ) do
            build_geojson_from_sql(sites_sql)
          end
        else
          build_geojson_from_sql(sites_sql)
        end

        render json: geojson, adapter: nil, serializer: nil
      end

      # ---------------------------
      # CSV (/data.csv)
      # ---------------------------
      format.csv do
        csv_data = if unfiltered_request?
          Rails.cache.fetch(
            cache_key_for("csv"),
            expires_in: 10.minutes
          ) do
            build_csv(@data.xrons)
          end
        else
          build_csv(@data.xrons)
        end

        render plain: csv_data,
               content_type: "text/csv",
               filename: "data_#{Date.today}.csv"
      end
    end
  end

  private

  # ---------------------------
  # Helpers for caching
  # ---------------------------

  def unfiltered_request?
    filter_params.blank? && select_params.blank?
  end

  def cache_key_for(suffix)
    # bump this version if you change SQL / structure
    "xronos_data/unfiltered/v1/#{suffix}"
  end

  def build_geojson_from_sql(sites_sql)
    Site.connection.exec_query(
      Site
        .select("json_agg(geojson) AS measurements")
        .from("(select jsonb_build_object(
          'type', 'Feature',
          'geometry', jsonb_build_object(
              'type', 'Point',
              'coordinates', jsonb_build_array(lng, lat)
          ),
          'properties', jsonb_build_object(
              'name', name,
              'id', id
          )
        ) AS geojson from (#{sites_sql}) AS subquery1) AS subquery2")
        .to_sql
    )[0]["measurements"]
  end

  def build_csv(xrons_relation)
    ids = xrons_relation.pluck(:id)
    return +"id\n" if ids.empty? # avoid invalid COPY

    query = "COPY (SELECT * FROM data_views WHERE id IN (" +
            ids.join(", ") +
            ") ) TO STDOUT WITH CSV HEADER"

    connection = ActiveRecord::Base.connection.raw_connection
    csv_data   = +""

    connection.copy_data(query) do
      while (row = connection.get_copy_data)
        csv_data << row
      end
    end

    csv_data
  end

  # ---------------------------
  # Strong params
  # ---------------------------

  def filter_params
    params.fetch(:filter, {}).permit(
      { c14s: [
        :lab_identifier,
        { lab_identifier: [] },
        { bp: [] }
      ] },
      { cals: [
        :tpq,
        { tpq: [] },
        :taq,
        { taq: [] }
      ] },
      { c14_labs: [
        :name,
        { name: [] }
      ] },
      { contexts: [
        :name,
        { name: [] }
      ] },
      { materials: [
        :name,
        { name: [] }
      ] },
      { taxons: [
        :name,
        { name: [] }
      ] },
      { typos: [
        :name,
        { name: [] }
      ] },
      { references: [
        :short_ref,
        { short_ref: [] }
      ] },
      { sites: [
        :name,
        { name: [] },
        :country_code,
        { country_code: [] },
        { lat: [] },
        { lng: [] }
      ] },
      { site_types: [
        :name,
        { name: [] }
      ] }
    )
  end

  # TODO: is this safe???
  def select_params
    params.fetch(:select, {})
  end
end
