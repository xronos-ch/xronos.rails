# frozen_string_literal: true

class XronosDataController < ApplicationController
  def turn_off_lasso
    session[:spatial_lasso_selection] = nil
    redirect_to request.env['HTTP_REFERER']
  end

  def reset_manual_table_selection
    session[:manual_table_selection] = nil
    redirect_to request.env['HTTP_REFERER']
  end

  def index
    @raw_filter_params = filter_params
    @data = XronosData.new(@raw_filter_params.except(:type), select_params)
    @data_types = @raw_filter_params.fetch(:type, %w[c14 dendro]).map(&:downcase) & %w[c14 dendro]
    if @data_types.include?("dendro") || params[:type] == "dendro"
      @dendro_data = XronosData.new(@raw_filter_params.except(:type), select_params, data_type: :dendro)
    end

    respond_to do |format|
      format.html do
        @filtered_count = @total_count = 0
        set_counts if @data_types.include?("c14")

        xrons_relation = @data.xrons.includes(
          sample: [
            :material,
            :taxon,
            { context: :site }
          ]
        )

        begin
          if @dendro_data && @data_types.include?("dendro")
            dendros = @dendro_data.xrons.includes(sample: { context: :site }).order(:id)
            @dendro_pagy, @dendro_xrons = pagy(:countish, dendros, page_param: :dendros_page)
          end
          @pagy, @xrons = if !@data_types.include?("c14")
                            [nil, []]
                          elsif unfiltered_request?
                            Rails.cache.fetch(
                              cache_key_for("html_page_#{params[:page] || 1}"),
                              expires_in: 10.minutes
                            ) do
                              pagy(:countish, xrons_relation)
                            end
                          else
                            pagy(:countish, xrons_relation)
                          end
        rescue Pagy::OverflowError
          head :not_found and return
        end

        if @dendro_pagy
          @filtered_count += @dendro_data.xrons.except(:select, :order).distinct.count(:id)
          @total_count += @dendro_data.everything.count(:id)
        end

        render layout: 'full_page'
      end

      format.json do
        if params[:type] == "dendro"
          render json: @dendro_data.xrons.as_json(only: Dendro::EXPORT_COLUMNS)
        elsif params[:schema] == C14::MIAARD::SCHEMA
          payload = if unfiltered_request?
                      Rails.cache.fetch(cache_key_for('json_miaard'), expires_in: 10.minutes) do
                        build_miaard_payload(@data.xrons)
                      end
                    else
                      build_miaard_payload(@data.xrons)
                    end
          send_miaard_json(payload, "xronos_data_miaard_#{Date.today}.json")
        elsif unfiltered_request?
          send_cached_standard_json
        else
          render json: @data
        end
      end

      format.geojson do
        geojson = if unfiltered_request?
                    Rails.cache.fetch(
                      cache_key_for('geojson_with_dendro'),
                      expires_in: 10.minutes
                    ) do
                      build_geojson_from_sql(filtered_sites_sql)
                    end
                  else
                    build_geojson_from_sql(filtered_sites_sql)
                  end

        render json: geojson, adapter: nil, serializer: nil
      end

      format.csv do
        if params[:type] == "dendro"
          next send_data build_csv(@dendro_data.xrons, table: "dendros", columns: Dendro::EXPORT_COLUMNS),
                           type: "text/csv; charset=utf-8",
                           filename: "dendro_data_#{Date.today}.csv"
        end

        csv_data = if unfiltered_request?
                     Rails.cache.fetch(
                       cache_key_for('csv'),
                       expires_in: 10.minutes
                     ) do
                       build_csv(@data.xrons)
                     end
                   else
                     build_csv(@data.xrons)
                   end

        send_data csv_data,
                  type: 'text/csv; charset=utf-8',
                  filename: "xronos_data_#{Date.today}.csv",
                  disposition: 'attachment'
      end
    end
  end

  private

  def set_counts
    if unfiltered_request?
      base_relation = @data.everything.except(:select, :includes, :order)

      @total_count = @filtered_count =
        Rails.cache.fetch(cache_key_for('total_count'), expires_in: 10.minutes) do
          base_relation.distinct.count(:id)
        end
    else
      filtered_relation = @data.xrons.except(:select, :includes, :order)
      total_relation    = @data.everything.except(:select, :includes, :order)

      @filtered_count = filtered_relation.distinct.count(:id)
      @total_count    = Rails.cache.fetch(cache_key_for('total_count'), expires_in: 10.minutes) do
        total_relation.distinct.count(:id)
      end
    end
  end

  def unfiltered_request?
    filter_params.blank? && select_params.blank?
  end

  def cache_key_for(suffix)
    "xronos_data/unfiltered/v2/#{suffix}"
  end

  def filtered_sites_sql
    relations = []
    relations << @data.xrons if @data_types.include?("c14")
    relations << @dendro_data.xrons if @dendro_data && @data_types.include?("dendro")
    relations << @data.xrons.none if relations.empty?

    relations.map do |relation|
      relation.reselect("sites.id", "sites.lng", "sites.lat", "sites.name").reorder(nil).distinct.to_sql
    end.join(" UNION ")
  end

  def build_geojson_from_sql(sites_sql)
    geojson_sql = <<~SQL.squish
      (
        SELECT jsonb_build_object(
          'type', 'Feature',
          'geometry', jsonb_build_object(
            'type', 'Point',
            'coordinates', jsonb_build_array(lng, lat)
          ),
          'properties', jsonb_build_object(
            'name', name,
            'id', id
          )
        ) AS geojson
        FROM (#{sites_sql}) AS subquery1
        WHERE lat IS NOT NULL
          AND lng IS NOT NULL
      ) AS subquery2
    SQL

    Site.connection.exec_query(
      Site.unscoped
        .select("COALESCE(json_agg(geojson), '[]'::json) AS measurements")
        .from(geojson_sql)
        .to_sql
    )[0]['measurements']
  end

  def build_csv(xrons_relation, table: "data_views", columns: nil)
    columns_sql = columns ? columns.map { |column| ActiveRecord::Base.connection.quote_column_name(column) }.join(", ") : "*"
    ids_subquery = xrons_relation.reorder(nil).select(:id).to_sql

    query = <<~SQL.squish
      COPY (
        SELECT #{columns_sql}
        FROM #{table}
        WHERE id IN (#{ids_subquery})
      ) TO STDOUT WITH CSV HEADER
    SQL

    connection = ActiveRecord::Base.connection.raw_connection
    csv_data   = +''

    connection.copy_data(query) do
      while (row = connection.get_copy_data)
        csv_data << row
      end
    end

    csv_data
  end

  def build_miaard_payload(xrons_relation)
    c14s = xrons_relation
           .includes(sample: [:taxon, { context: :site }])
           .reorder(:id)

    entries = C14::MIAARD.collection(c14s).map(&:to_h)
    { entries: entries }
  end

  def send_miaard_json(payload, filename)
    send_data JSON.pretty_generate(payload),
              type: 'application/json; charset=utf-8',
              filename: filename,
              disposition: 'attachment'
  end

  def send_cached_standard_json
    json_payload = Rails.cache.fetch(cache_key_for('json'), expires_in: 10.minutes) do
      @data.as_json
    end

    render json: json_payload
  end

  def filter_params
    params.fetch(:filter, ActionController::Parameters.new).permit(
      { type: [], dendros: [:waney_edge, :is_anchored] },
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

  def select_params
    params.fetch(:select, {})
  end
end
