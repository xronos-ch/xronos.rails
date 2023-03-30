class Issues::TaxonsController < IssuesController
  load_and_authorize_resource

  # GET /issues/taxons/:issue
  def index
    if params.has_key?(:issue)
      @taxons = Taxon.send(params[:issue])
    else
      @taxons = Taxon.all
    end

    @taxons = @taxons.with_samples_count

    if params.has_key?(:search)
      @taxons = @taxons.search params[:search]
    end

    if params.has_key?(:taxons_order_by)
      order = { params[:taxons_order_by] => params.fetch(:taxons_order, "asc") }
    else
      order = :id
    end
    @taxons = @taxons.reorder(order)

    respond_to do |format|
      format.html { @pagy, @taxons = pagy(@taxons) }
    end
  end

  private

end
