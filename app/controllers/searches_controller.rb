class SearchesController < ApplicationController

  def index
    @results = PgSearch.multisearch(search_params[:q])
    @results = @results.where.not(searchable_type: 'Dendro').or(
      @results.where(searchable_type: 'Dendro', searchable_id: Dendro.select(:id))
    )

    @n_results = @results.count
    @n_sites = @results.where(searchable_type: "Site").count
    @n_c14s = @results.where(searchable_type: "C14").count
    @n_dendros = @results.where(searchable_type: 'Dendro').count
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
        dendros = @results.select { |result| result.searchable_type == 'Dendro' }.map(&:searchable)
        ActiveRecord::Associations::Preloader.new(records: dendros, associations: { sample: { context: :site } }).call
      }
      format.json { 
        render json: @results.limit(500) 
      }
    end
  end

  private

  def search_params
    params.permit(:q, :type, :page, :format)
  end

  def searchable_types
    [ "Site", "C14", "Dendro", "Reference" ]
  end

end
