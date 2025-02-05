class Issues::DendrosController < IssuesController
  load_and_authorize_resource

  # GET /issues/dendros/:issue
  def index
    if issue_param.present?
      @dendros = Dendro.send(issue_param)
    else
      @dendros = Dendro.all
    end

    if params.has_key?(:search)
      @dendros = @dendros.search params[:search]
    end

    if params.has_key?(:dendros_order_by)
      order = { params[:dendros_order_by] => params.fetch(:dendros_order, "asc") }
    else
      order = :id
    end
    @dendros = @dendros.reorder(order)

    respond_to do |format|
      format.html { @pagy, @dendros = pagy(@dendros) }
    end
  end

  private

  def issues
    Dendro.issues
  end

end
