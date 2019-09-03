module Api
  module V1
    class DataController < ApplicationController
      respond_to :json

      def index
        @data = Measurement.all

        unless params[:query_labnr].nil?
          @data = @data.where(
              "measurements.labnr LIKE ?", params[:query_labnr]
          ).all
        end

      end

      def show
        @date = Measurement.find(params[:id])
      end
    end
  end
end
