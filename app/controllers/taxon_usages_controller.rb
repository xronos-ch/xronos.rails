class TaxonUsagesController < ApplicationController
  
  # GET /taxon_usages/:id
  def show
    @taxon_usage = TaxonUsage.new(id: params[:id])
    render @taxon_usage
  end

  # GET /taxon_usages?name=...
  def index
    if params[:name]
      @taxon_match = GBIF::Species.match(
        scientificName: params[:name],
        strict: false
      )
      render partial: "taxon_usages/taxon_match", locals: { 
        taxon_match: @taxon_match,
        frame_id: params.fetch(:frame_id)
      }
    end
  end

end
