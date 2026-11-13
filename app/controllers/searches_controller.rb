class SearchesController < ApplicationController

  def index
    @results = PgSearch.multisearch(search_params[:q]).merge(visible_search_documents)

    @n_results = @results.count
    @n_sites = @results.where(searchable_type: "Site").count
    @n_c14s = @results.where(searchable_type: "C14").count
    @n_references = @results.where(searchable_type: "Reference").count

    type_param = search_params[:type]
    if type_param.present? && searchable_types.include?(type_param)
      @results = @results.where(searchable_type: type_param)
      @search_type = type_param
    end

    respond_to do |format|
      format.html {
        @results = @results.includes(:searchable)
        @pagy, @results = pagy(:offset, @results)
      }
      format.json { 
        render json: @results.limit(500) 
      }
    end
  end

  private

  def visible_search_documents
    documents = PgSearch::Document.all
    searchable_types.map do |type|
      documents.where(searchable_type: type, searchable_id: type.constantize.select(:id))
    end.reduce(:or)
  end

  def search_params
    params.permit(:q, :type, :page, :format)
  end

  def searchable_types
    [ "Site", "C14", "Reference" ]
  end

end
