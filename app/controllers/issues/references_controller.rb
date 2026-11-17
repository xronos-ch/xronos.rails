class Issues::ReferencesController < IssuesController
  load_and_authorize_resource

  # GET /issues/references/:issue
  def index
    @references = issue_relation_for(Reference)

    if params.has_key?(:search)
      @references = @references.search params[:search]
    end

    if params.has_key?(:references_order_by)
      order = { params[:references_order_by] => params.fetch(:references_order, "asc") }
    else
      order = :id
    end
    @references = @references.reorder(order)

    @references = @references.with_citations_count

    respond_to do |format|
      format.html { @pagy, @references = pagy(:offset, @references) }
    end
  end

  private

  def issues
    Reference.issues
  end

end
