class Issues::SamplesController < IssuesController
  load_and_authorize_resource

  # GET /issues/samples/:issue
  def index
    @samples = issue_relation_for(Sample)

    if params.has_key?(:search)
      @samples = @samples.search params[:search]
    end

    if params.has_key?(:samples_order_by)
      order = { params[:samples_order_by] => params.fetch(:samples_order, "asc") }
    else
      order = :id
    end
    @samples = @samples.reorder(order)

    respond_to do |format|
      format.html { @pagy, @samples = pagy(@samples) }
    end
  end

  private

  def issues
    Sample.issues
  end

end
