class Issues::C14sController < IssuesController
  load_and_authorize_resource

  # GET /issues/c14s/:issue
  def index
    if issue_param.present?
      @c14s = C14.send(issue_param)
    else
      @c14s = C14.all
    end

    if params.has_key?(:search)
      @c14s = @c14s.search params[:search]
    end

    if params.has_key?(:c14s_order_by)
      order = { params[:c14s_order_by] => params.fetch(:c14s_order, "asc") }
    else
      order = :id
    end
    @c14s = @c14s.reorder(order)

    respond_to do |format|
      format.html { @pagy, @c14s = pagy(@c14s) }
    end
  end

  private

  def issues
    C14.issues
  end

end
