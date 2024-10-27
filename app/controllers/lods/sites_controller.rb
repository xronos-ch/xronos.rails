class Lods::SitesController < LodsController
  load_and_authorize_resource

  # GET /issues/sites/:issue
  def index
    if lod_param.present?
      @sites = Site.send(lod_param)
    else
      @sites = Site.all
    end

    if params.has_key?(:search)
      @sites = @sites.search params[:search]
    end

    if params.has_key?(:sites_order_by)
      order = { params[:sites_order_by] => params.fetch(:sites_order, "asc") }
    else
      order = :id
    end
    @sites = @sites.reorder(order)

    @sites = @sites.with_counts

    respond_to do |format|
      format.html { @pagy, @sites = pagy(@sites) }
    end
  end

  private

  def lods
    Site.lods
  end

end
