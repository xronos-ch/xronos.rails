class SiteNameSuggestionsController < ApplicationController
  def index
    authorize! :search, Site

    @sites = Site.search_name_matches(
      params[:q],
      exclude_id: params[:exclude_id],
      limit: params[:limit]
    )

    render 'sites/index', formats: :json
  end
end
