class Issues::SamplesController < IssuesController
  load_and_authorize_resource

  # GET /issues/samples/:issue
  def index
    if params[:issue] == "missing"
      @samples = Sample.missing
    else
      @samples = Sample.all
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

end
