module Api
  module V1
    class DataController < ApplicationController
      respond_to :json

      def index
        @data = Measurement.all
      end

      def show
        @date = Measurement.find(params[:id])
      end
    end
  end
end
