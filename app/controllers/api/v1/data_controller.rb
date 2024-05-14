module Api
  module V1
    class DataController < ApplicationController
    
      before_action only: [:create, :update, :destroy] do
        doorkeeper_authorize! :admin
      end
      
      respond_to :json
      before_action :valid_query, only: [:index]

      rescue_from ActionController::UnpermittedParameters do
        render :nothing => true, :status => :bad_request
      end
            
      def index
  
        @data ||= C14.includes(
          :c14_lab,
          {sample: [:material,
            :taxon,
            {context:
              [{site:
                :site_types},
                :typos]}]},
          :references
        )

        # lab_identifier (v1: labnr)
        unless params[:query_labnr].nil?
          @data = @data.where(
              lab_identifier: params[:query_labnr].split('|')
          )
        end

        # site name
        unless params[:query_site].nil?
          @data = @data.where(
            sites: { :name => params[:query_site].split('|') }
          )
        end

        # site type
        unless params[:query_site_type].nil?
          @data = @data.where(
            site_types: { :name => params[:query_site_type].split('|') }
          )
        end

        # country
        unless params[:query_country].nil?
          @data = @data.where(
            sites: { :country_code => params[:query_country].split('|') }
          )
        end

        # feature
        unless params[:query_feature].nil?
          @data = @data.where(
            contexts: { :name => params[:query_feature].split('|') }
          )
        end

        # material
        unless params[:query_material].nil?
          @data = @data.where(
            materials: { :name => params[:query_material].split('|') }
          )
        end

        # species
        unless params[:query_species].nil?
          @data = @data.where(
            taxons: { :name => params[:query_species].split('|') }
          )
        end
        
        where_clause = @data.to_sql[/ WHERE .*/]
        
        query = %q[
SELECT json_agg(json_build_object('measurement', measurement)) AS measurements
FROM (
  SELECT json_build_object(
    'id', c14s.id,
    'labnr', c14s.lab_identifier,
    'bp', c14s.bp,
    'std', c14s.std,
    'cal_bp', c14s.cal_bp,
    'cal_std', c14s.cal_std,
    'delta_c13', c14s.delta_c13,
    'source_database', '',
    'lab_name', '',
    'material', materials.name,
    'species', taxons.name,
    'feature', contexts.name,
    'feature_type', (
    SELECT st.name
    FROM site_types st
    JOIN site_types_sites sts ON st.id = sts.site_type_id
    JOIN contexts ctx ON ctx.site_id = sts.site_id
    JOIN samples samp ON samp.context_id = ctx.id
    WHERE samp.id = samples.id AND st.name IS NOT NULL LIMIT 1
    ),
    'site', sites.name,
    'country', sites.country_code,
    'lat', sites.lat::text,
    'lng', sites.lng::text,
    'site_type', (
      SELECT st.name
      FROM site_types st
      JOIN site_types_sites sts ON st.id = sts.site_type_id
      JOIN contexts ctx ON ctx.site_id = sts.site_id
      JOIN samples samp ON samp.context_id = ctx.id
      WHERE samp.id = samples.id AND st.name IS NOT NULL LIMIT 1
    ),
    'periods', COALESCE((
      SELECT json_agg(json_build_object('periode', tp.name))
      FROM typos tp
      WHERE tp.sample_id = samples.id
    ), '[]'::json),
    'typochronological_units', COALESCE((
    SELECT json_agg(json_build_object('typochronological_unit', tp.name))
      FROM typos tp
      WHERE tp.sample_id = samples.id
    ), '[]'::json),
    'ecochronological_units', COALESCE((
    SELECT json_agg(json_build_object('ecochronological_unit', tp.name))
      FROM typos tp
      WHERE tp.sample_id = samples.id
    ), '[]'::json),
    'reference', COALESCE((
    SELECT json_agg(json_build_object('reference', ref.short_ref))
      FROM "references" ref
      JOIN citations cit ON ref.id = cit.reference_id
      WHERE cit.citing_type = 'C14' AND cit.citing_id = c14s.id
      ), '[]'::json)
  ) AS measurement
  FROM c14s
  LEFT JOIN samples ON samples.id = c14s.sample_id
  LEFT JOIN materials ON materials.id = samples.material_id
  LEFT JOIN taxons ON taxons.id = samples.taxon_id
  LEFT JOIN contexts ON contexts.id = samples.context_id
  LEFT JOIN sites ON sites.id = contexts.site_id
] + where_clause + ") sub;"

                #logger.debug C14.connection.exec_query(query).to_yaml
        render json: C14.connection.exec_query(query)[0]['measurements'], adapter: nil, serializer: nil
        
      end

      def show
        @date = C14.find(params[:id])
      end
      
      private
      
      def valid_query
        params.permit(:format, :query_labnr, :query_site, :query_site_type, :query_country, :query_feature, :query_material, :query_species)
      end
    end
  end
end
