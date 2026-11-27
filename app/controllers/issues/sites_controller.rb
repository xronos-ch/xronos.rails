class Issues::SitesController < IssuesController
  load_and_authorize_resource

  # GET /issues/sites/:issue
  def index
    @water_check_report = Site::WaterCheck.report
    @water_findings = @water_check_report&.fetch(:findings) || {}
    @sites = if issue_param == 'coordinates_in_water'
      Site.coordinates_in_water(@water_findings)
    else
      issue_relation_for(Site)
    end
    @sites = @sites.search(params[:search]) if params.key?(:search)
    @sites = order_sites(@sites).with_counts

    respond_to do |format|
      format.html { @pagy, @sites = pagy(:offset, @sites) }
    end
  end

  private

  def order_sites(sites)
    if params.key?(:sites_order_by)
      sites.reorder(params[:sites_order_by] => params.fetch(:sites_order, 'asc'))
    elsif issue_param == 'coordinates_in_water' && @water_findings.any?
      sites.in_order_of(:id, @water_findings.keys, filter: false)
    else
      sites.reorder(:id)
    end
  end

  def issues
    Site.issues
  end

end
