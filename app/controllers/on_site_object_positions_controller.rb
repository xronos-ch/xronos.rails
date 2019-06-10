class OnSiteObjectPositionsController < ApplicationController
  before_action :set_on_site_object_position, only: [:show, :edit, :update, :destroy]

  # GET /on_site_object_positions
  # GET /on_site_object_positions.json
  def index
    @on_site_object_positions = OnSiteObjectPosition.all
  end

  # GET /on_site_object_positions/1
  # GET /on_site_object_positions/1.json
  def show
  end

  # GET /on_site_object_positions/new
  def new
    @on_site_object_position = OnSiteObjectPosition.new
  end

  # GET /on_site_object_positions/1/edit
  def edit
  end

  # POST /on_site_object_positions
  # POST /on_site_object_positions.json
  def create
    @on_site_object_position = OnSiteObjectPosition.new(on_site_object_position_params)

    respond_to do |format|
      if @on_site_object_position.save
        format.html { redirect_to @on_site_object_position, notice: 'On site object position was successfully created.' }
        format.json { render :show, status: :created, location: @on_site_object_position }
      else
        format.html { render :new }
        format.json { render json: @on_site_object_position.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /on_site_object_positions/1
  # PATCH/PUT /on_site_object_positions/1.json
  def update
    respond_to do |format|
      if @on_site_object_position.update(on_site_object_position_params)
        format.html { redirect_to @on_site_object_position, notice: 'On site object position was successfully updated.' }
        format.json { render :show, status: :ok, location: @on_site_object_position }
      else
        format.html { render :edit }
        format.json { render json: @on_site_object_position.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /on_site_object_positions/1
  # DELETE /on_site_object_positions/1.json
  def destroy
    @on_site_object_position.destroy
    respond_to do |format|
      format.html { redirect_to on_site_object_positions_url, notice: 'On site object position was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_on_site_object_position
      @on_site_object_position = OnSiteObjectPosition.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def on_site_object_position_params
      params.require(:on_site_object_position).permit(:feature, :site_grid_square, :coord_reference_system, :coord_X, :coord_Y, :coord_Z)
    end
end
