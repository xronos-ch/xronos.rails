module Api
  module V1
    class DataController < ApplicationController
      respond_to :json

      def index
        @data ||= Measurement.includes({c14_measurement: :source_database}, :lab, sample: {arch_object: [{site_phase: {site: :country}}, :on_site_object_position, :material, :species]})

        # labnr
        unless params[:query_labnr].nil?
          @data = @data.where(
              labnr: params[:query_labnr].split('|')
          ).all
        end

        # site name
        unless params[:query_site].nil?
          @data = @data.where(
            sample: {arch_object: {site_phase: {sites: {:name => params[:query_site].split('|')}}}}
          ).all
        end

        # site type
        unless params[:query_site_type].nil?
          @data = @data.where(
            sample: {arch_object: {site_phase: {site_types: {name: params[:query_site_type].split('|')}}}}
          ).all
        end

        # country
        unless params[:query_country].nil?
          @data = @data.where(
            sample: {arch_object: {site_phase: {site: {countries: {name: params[:query_country].split('|')}}}}}
          ).all
        end

        # feature
        unless params[:query_feature].nil?
          @data = @data.where(
            sample: {arch_object: {on_site_object_positions: {feature: params[:query_feature].split('|')}}}
          ).all
        end

        # material
        unless params[:query_material].nil?
          @data = @data.where(
            sample: {arch_object: {materials: {name: params[:query_material].split('|')}}}
          ).all
        end

        # species
        unless params[:query_species].nil?
          @data = @data.where(
            sample: {arch_object: {species: {name: params[:query_species].split('|')}}}
          ).all
        end

      end

      def show
        @date = Measurement.find(params[:id])
      end
    end
  end
end
