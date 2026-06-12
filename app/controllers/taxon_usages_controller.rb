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
    end

    @taxon = Taxon.find(params[:taxon_id])

    render partial: "taxon_usages/taxon_match", locals: { 
      taxon: @taxon,
      taxon_match: @taxon_match
    }
  end

end
