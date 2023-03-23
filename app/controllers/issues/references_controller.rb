class Issues::ReferencesController < IssuesController
  load_and_authorize_resource

  # GET /issues/references/:issue
  def index
    if params.has_key?(:issue)
      @references = Reference.send(params[:issue])
    else
      @references = Reference.all
    end

    if params.has_key?(:references_order_by)
      order = { params[:references_order_by] => params.fetch(:references_order, "asc") }
    else
      order = :id
    end
    @references = @references.reorder(order)

    @references = @references.with_citations_count

    respond_to do |format|
      format.html { @pagy, @references = pagy(@references) }
    end
  end

end
