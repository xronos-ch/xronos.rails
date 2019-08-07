class EcochronologicalUnitsController < ApplicationController
  before_action :set_ecochronological_unit, only: [:show, :edit, :update, :destroy]

  # GET /ecochronological_units
  # GET /ecochronological_units.json
  def index
    @ecochronological_units = EcochronologicalUnit.all
  end

  # GET /ecochronological_units/1
  # GET /ecochronological_units/1.json
  def show
  end

  # GET /ecochronological_units/new
  def new
    @ecochronological_unit = EcochronologicalUnit.new
  end

  # GET /ecochronological_units/1/edit
  def edit
  end

  # POST /ecochronological_units
  # POST /ecochronological_units.json
  def create
    @ecochronological_unit = EcochronologicalUnit.new(ecochronological_unit_params)

    respond_to do |format|
      if @ecochronological_unit.save
        format.html { redirect_to @ecochronological_unit, notice: 'Ecochronological unit was successfully created.' }
        format.json { render :show, status: :created, location: @ecochronological_unit }
      else
        format.html { render :new }
        format.json { render json: @ecochronological_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ecochronological_units/1
  # PATCH/PUT /ecochronological_units/1.json
  def update
    respond_to do |format|
      if @ecochronological_unit.update(ecochronological_unit_params)
        format.html { redirect_to @ecochronological_unit, notice: 'Ecochronological unit was successfully updated.' }
        format.json { render :show, status: :ok, location: @ecochronological_unit }
      else
        format.html { render :edit }
        format.json { render json: @ecochronological_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ecochronological_units/1
  # DELETE /ecochronological_units/1.json
  def destroy
    @ecochronological_unit.destroy
    respond_to do |format|
      format.html { redirect_to ecochronological_units_url, notice: 'Ecochronological unit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ecochronological_unit
      @ecochronological_unit = EcochronologicalUnit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ecochronological_unit_params
      params.require(:ecochronological_unit).permit(:name, :approx_start_time, :approx_end_time, :parent_id)
    end
end
