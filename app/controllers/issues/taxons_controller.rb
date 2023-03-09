class Issues::TaxonsController < ApplicationController
  layout "curate"
  include Pagy::Backend

  load_and_authorize_resource

  # GET /issues/taxons/:issue
  def index
    if params[:issue] == "unknown_taxon"
      @taxons = Taxon.unknown_taxon
    else
      @taxons = Taxon.all
    end

    @taxons = @taxons.with_samples_count

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

end
