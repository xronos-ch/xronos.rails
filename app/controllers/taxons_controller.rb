class TaxonsController < ApplicationController
  include Tabulatable

  load_and_authorize_resource

  before_action :set_taxon, only: [:show, :edit, :update, :destroy]

  # GET /taxons
  # GET /taxons.json
  # GET /taxons.csv
  def index
    @taxons = Taxon.all
    
    respond_to do |format|
      format.csv {
        @taxons = @taxons.select(index_csv_template)
        render csv: @taxons
      }
    end
  end

  # GET /taxons/search.json
  def search
    @taxons = Taxon.search(params[:q])

    respond_to do |format|
      format.json  {
        render :index
      }
    end
  end

  # GET /taxon/new
  def new
    @taxon = Taxon.new
  end

  # GET /taxon/1/edit
  def edit
  end

  # POST /taxon
  # POST /taxon.json
  def create
    @taxon = Taxon.new(taxon_params)

    respond_to do |format|
      if @taxon.save
        format.html { redirect_back fallback_location: root_path, notice: 'Taxon was successfully created.' }
        format.json { render :show, status: :created, location: @taxon }
      else
        format.html { render :new }
        format.json { render json: @taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /taxon/1
  # PATCH/PUT /taxon/1.json
  def update
    respond_to do |format|
      if @taxon.update(taxon_params)
        format.html { redirect_back fallback_location: root_path, notice: 'Taxon was successfully updated.' }
        format.json { render :show, status: :ok, location: @taxon }
      else
        format.html { render :edit }
        format.json { render json: @taxon.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /taxon/1
  # DELETE /taxon/1.json
  def destroy
    @taxon.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, notice: 'Taxon was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_taxon
      @taxon = Taxon.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def taxon_params
      params.require(:taxon).permit([ :name, :gbif_id, :revision_comment ])
    end
end
