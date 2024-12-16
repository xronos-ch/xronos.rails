module Api
  module V1
    class XronosDataController < ApplicationController
    
      before_action only: [:create, :update, :destroy] do
        doorkeeper_authorize! :admin
      end
      
      respond_to :json
      before_action :valid_query, only: [:index]

      rescue_from ActionController::UnpermittedParameters do
        render :nothing => true, :status => :bad_request
      end
            
      def index
  
        @data ||= DataView.all
            
        # Specify the file name you want to check in the public directory
        file_path = Rails.root.join("public", "all_data.json")
        
        # Check if none of the params keys start with "query_" and if the file exists
        if params.keys.none? { |key| key.to_s.start_with?('query_') } && File.exist?(file_path)
            send_file(file_path)
            return
        end

        # lab_identifier (v1: labnr)
        unless params[:query_labnr].nil?
          @data = @data.where(
              labnr: params[:query_labnr].split('|')
          )
        end

        # site name
        unless params[:query_site].nil?
          @data = @data.where(
            site: params[:query_site].split('|')
          )
        end

        # site type
        unless params[:query_site_type].nil?
          @data = @data.where(
            site_type: params[:query_site_type].split('|')
          )
        end

        # country
        unless params[:query_country].nil?
          @data = @data.where(
            country: params[:query_country].split('|')
          )
        end

        # feature
        unless params[:query_feature].nil?
          @data = @data.where(
            feature: params[:query_feature].split('|')
          )
        end

        # material
        unless params[:query_material].nil?
          @data = @data.where(
            material: params[:query_material].split('|')
          )
        end

        # species
        unless params[:query_species].nil?
          @data = @data.where(
            species: params[:query_species].split('|')
          )
        end
        
        #render json: @data.to_json      
        render json: C14.connection.exec_query(DataView.select("json_agg(json_build_object('measurement', subquery)) AS measurements").from(@data).to_sql)[0]['measurements'], adapter: nil, serializer: nil
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
