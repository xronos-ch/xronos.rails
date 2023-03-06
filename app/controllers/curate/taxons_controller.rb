class Curate::TaxonsController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  # GET /curate/taxons
  def index
    if params[:issue] == "uncontrolled"
      @taxons = Taxon.uncontrolled
    else
      @taxons = Taxon.all
    end

    @taxons = @taxons.with_samples_count

    respond_to do |format|
      format.html { @pagy, @taxons = pagy(@taxons) }
    end
  end

end
