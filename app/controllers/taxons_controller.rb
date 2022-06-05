class TaxonsController < ApplicationController
  load_and_authorize_resource

  before_action :set_taxon, only: [:show, :edit, :update, :destroy]

  # GET /taxon
  # GET /taxon.json
  def index
    @taxon = Taxon.all
  end

  # GET /taxon/1
  # GET /taxon/1.json
  def show
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
        format.html { redirect_to @taxon, notice: 'Taxon was successfully created.' }
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
        format.html { redirect_to @taxon, notice: 'Taxon was successfully updated.' }
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
      format.html { redirect_to taxon_index_url, notice: 'Taxon was successfully destroyed.' }
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
      params.require(:taxon).permit(:name)
    end
end