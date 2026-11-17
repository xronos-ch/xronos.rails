class Issues::DendrosController < IssuesController
  load_and_authorize_resource

  # GET /issues/dendros/:issue
  def index
    @dendros = issue_relation_for(Dendro).includes(:chronology, sample: { context: :site })
    @dendros = @dendros.search(params[:search]) if params[:search].present?
    order = { id: params[:dendros_order] == "desc" ? :desc : :asc }
    @dendros = @dendros.reorder(order)

    respond_to do |format|
      format.html { @pagy, @dendros = pagy(:offset, @dendros) }
    end
  end

  private

  def issues
    Dendro.issues
  end

end
