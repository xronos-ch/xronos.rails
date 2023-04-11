class TaxonUsagesController < ApplicationController
  
  def show
    @taxon_usage = TaxonUsage.new(id: params[:id])
    render partial: "taxon_usage", locals: { taxon_usage: @taxon_usage }
  end

end
