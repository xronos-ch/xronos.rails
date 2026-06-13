##
# Wrapper for GBIF species match API (for autocomplete)
#
class GbifSearchController < ApplicationController
  def index
    return render json: [] if params[:q].blank?

    response = GBIF::Species.search(
      query: params[:q], 
      limit: 10,
    )

    # TODO should search everything but only select the canonical
    results = response.fetch("results", []).map do |r|
      {
        value: r["usageKey"],
        label: r["canonicalName"],
        rank: r["rank"]
      }
    end

    render json: results
  end
end

