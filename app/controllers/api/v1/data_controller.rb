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
          :source_database,
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
        
        @data = @data.to_a
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
