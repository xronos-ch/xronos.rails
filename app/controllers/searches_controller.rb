class SearchesController < ApplicationController
  include Pagy::Backend

  def index
    @results = PgSearch.multisearch(params[:q])

    respond_to do |format|
      format.html {
        @results = @results.includes(:searchable)
        @pagy, @results = pagy(@results)
      }
      format.json { 
        render json: @results.limit(500) 
      }
    end
  end

end
