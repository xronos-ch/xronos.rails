class Issues::UnknownTaxonsController < ApplicationController
  before_action :set_issues_unknown_taxon, only: %i[ show edit update destroy ]

  # GET /issues/unknown_taxons or /issues/unknown_taxons.json
  def index
    @issues_unknown_taxons = Issues::UnknownTaxon.all
  end

  # GET /issues/unknown_taxons/1 or /issues/unknown_taxons/1.json
  def show
  end

  # GET /issues/unknown_taxons/new
  def new
    @issues_unknown_taxon = Issues::UnknownTaxon.new
  end

  # GET /issues/unknown_taxons/1/edit
  def edit
  end

  # POST /issues/unknown_taxons or /issues/unknown_taxons.json
  def create
    @issues_unknown_taxon = Issues::UnknownTaxon.new(issues_unknown_taxon_params)

    respond_to do |format|
      if @issues_unknown_taxon.save
        format.html { redirect_to issues_unknown_taxon_url(@issues_unknown_taxon), notice: "Unknown taxon issue was successfully created." }
        format.json { render :show, status: :created, location: @issues_unknown_taxon }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @issues_unknown_taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /issues/unknown_taxons/1 or /issues/unknown_taxons/1.json
  def update
    respond_to do |format|
      if @issues_unknown_taxon.update(issues_unknown_taxon_params)
        format.html { redirect_to issues_unknown_taxon_url(@issues_unknown_taxon), notice: "Unknown taxon issue was successfully updated." }
        format.json { render :show, status: :ok, location: @issues_unknown_taxon }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @issues_unknown_taxon.errors, status: :unprocessable_entity }
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
    def set_issues_unknown_taxon
      @issues_unknown_taxon = Issues::UnknownTaxon.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def issues_unknown_taxon_params
      params.require(:issues_unknown_taxon).permit(:taxon_id)
    end
end
