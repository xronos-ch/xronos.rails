class Issues::ContextsController < IssuesController
  load_and_authorize_resource

  # GET /issues/contexts/:issue
  def index
    @contexts = issue_relation_for(::Context)

    if params.has_key?(:search)
      @contexts = @contexts.search(params[:search])
    end

    @suggestions_count = @contexts
                           .merge(::Context.with_functional_classification_suggestions)
                           .count

    if params[:suggestions].present?
      @contexts = @contexts.merge(::Context.with_functional_classification_suggestions)
    end

    @contexts = @contexts.includes(
      site: :site_types,
      functional_classifications: [
        :functional_classification_category,
        :functional_classification_confidence
      ]
    )

    order =
      if params.has_key?(:contexts_order_by)
        { params[:contexts_order_by] => params.fetch(:contexts_order, "asc") }
      else
        :id
      end

    @contexts = @contexts.reorder(order)

    respond_to do |format|
      format.html { @pagy, @contexts = pagy(@contexts) }
    end
  end

  private

  def issues
    ::Context.issues
  end
end