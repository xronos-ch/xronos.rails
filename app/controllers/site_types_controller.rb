class SiteTypesController < ApplicationController
  include SupersedableController

  load_and_authorize_resource

  before_action :set_site_type, only: [:show, :edit, :update, :destroy]

  # GET /site_types
  # GET /site_types.json
  def index
    @site_types = SiteType.all
  end

  # GET /site_types/search.json
  def search
    @site_types = SiteType.search(params[:q])

    respond_to do |format|
      format.json  {
        render :index
      }
    end
  end

  # GET /site_types/1
  # GET /site_types/1.json
  def show
  end

  # GET /site_types/new
  def new
    @site_type = SiteType.new
  end

  # GET /site_types/1/edit
  def edit
  end

  # POST /site_types
  # POST /site_types.json
  def create
    @site_type = SiteType.new(site_type_params)

    respond_to do |format|
      if @site_type.save
        format.html { redirect_to @site_type, notice: 'Site type was successfully created.' }
        format.json { render :show, status: :created, location: @site_type }
      else
        format.html { render :new }
        format.json { render json: @site_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /site_types/1
  # PATCH/PUT /site_types/1.json
  def update
    respond_to do |format|
      if @site_type.update(site_type_params)
        format.html { redirect_to @site_type, notice: 'Site type was successfully updated.' }
        format.json { render :show, status: :ok, location: @site_type }
      else
        format.html { render :edit }
        format.json { render json: @site_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /site_types/1
  # DELETE /site_types/1.json
  def destroy
    @site_type.destroy
    respond_to do |format|
      format.html { redirect_to site_types_url, notice: 'Site type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site_type
      @site_type = SiteType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_type_params
      params.require(:site_type).permit(:name, :description)
    end
end
