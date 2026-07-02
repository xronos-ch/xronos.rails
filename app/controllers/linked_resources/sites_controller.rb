class LinkedResources::SitesController < ApplicationController
  before_action :authenticate_user!
  layout "curate"

  load_and_authorize_resource

  # GET /linked_resources/sites/:issue
  def index
    issue = params[:issue]&.to_sym
    if issue.present? && Site.linked_resource_issues.include?(issue)
      @sites = Site.public_send(issue)
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
      format.html do
        @pagy, @sites = pagy(:offset, @sites)
      end
    end
  end
end
