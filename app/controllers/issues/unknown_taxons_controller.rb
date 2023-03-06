class Issues::UnknownTaxonsController < ApplicationController
  include Pagy::Backend

  before_action :set_unknown_taxon, only: %i[ show edit update destroy ]

  # GET /issues/unknown_taxons or /issues/unknown_taxons.json
  def index
    #@unknown_taxons = Issues::UnknownTaxon.all
    @unknown_taxons = Taxon.joins(:unknown_taxon).with_samples_count

    respond_to do |format|
      format.html {
        @pagy, @unknown_taxons = pagy(@unknown_taxons)
      }
    end
  end

  # GET /issues/unknown_taxons/1 or /issues/unknown_taxons/1.json
  def show
  end

  # GET /issues/unknown_taxons/new
  def new
    @unknown_taxon = Issues::UnknownTaxon.new
  end

  # GET /issues/unknown_taxons/1/edit
  def edit
  end

  # POST /issues/unknown_taxons or /issues/unknown_taxons.json
  def create
    @unknown_taxon = Issues::UnknownTaxon.new(issues_unknown_taxon_params)

    respond_to do |format|
      if @unknown_taxon.save
        format.html { redirect_to issues_unknown_taxon_url(@unknown_taxon), notice: "Unknown taxon issue was successfully created." }
        format.json { render :show, status: :created, location: @unknown_taxon }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @unknown_taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /issues/unknown_taxons/1 or /issues/unknown_taxons/1.json
  def update
    respond_to do |format|
      if @unknown_taxon.update(issues_unknown_taxon_params)
        format.html { redirect_to issues_unknown_taxon_url(@unknown_taxon), notice: "Unknown taxon issue was successfully updated." }
        format.json { render :show, status: :ok, location: @unknown_taxon }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @unknown_taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  def bulk_update
    @selected_taxons = Taxon.where(id: params.fetch(:taxon_ids, []).compact)
    if params[:commit] == "match"
      @selected_taxons.find_each do |taxon|
        taxon.set_attributes_from_gbif_match(strict = false)
        taxon.save!
      end
    end
  end

  # DELETE /issues/unknown_taxons/1 or /issues/unknown_taxons/1.json
  def destroy
    @issues_unknown_taxon.destroy

    respond_to do |format|
      format.html { redirect_to issues_unknown_taxons_url, notice: "Unknown taxon issue was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unknown_taxon
      @unknown_taxon = Issues::UnknownTaxon.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def unknown_taxon_params
      params.require(:unknown_taxon).permit(:taxon_id)
    end
end
