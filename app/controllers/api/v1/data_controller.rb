module Api
  module V1
    class DataController < ApplicationController
      prepend_view_path Rails.root.join("app", "views", "v1", "data")

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
