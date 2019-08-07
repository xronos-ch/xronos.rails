class TypochronologicalUnitsController < ApplicationController
  before_action :set_typochronological_unit, only: [:show, :edit, :update, :destroy]

  # GET /typochronological_units
  # GET /typochronological_units.json
  def index
    @typochronological_units = TypochronologicalUnit.all
  end

  # GET /typochronological_units/1
  # GET /typochronological_units/1.json
  def show
  end

  # GET /typochronological_units/new
  def new
    @typochronological_unit = TypochronologicalUnit.new
  end

  # GET /typochronological_units/1/edit
  def edit
  end

  # POST /typochronological_units
  # POST /typochronological_units.json
  def create
    @typochronological_unit = TypochronologicalUnit.new(typochronological_unit_params)

    respond_to do |format|
      if @typochronological_unit.save
        format.html { redirect_to @typochronological_unit, notice: 'Typochronological unit was successfully created.' }
        format.json { render :show, status: :created, location: @typochronological_unit }
      else
        format.html { render :new }
        format.json { render json: @typochronological_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /typochronological_units/1
  # PATCH/PUT /typochronological_units/1.json
  def update
    respond_to do |format|
      if @typochronological_unit.update(typochronological_unit_params)
        format.html { redirect_to @typochronological_unit, notice: 'Typochronological unit was successfully updated.' }
        format.json { render :show, status: :ok, location: @typochronological_unit }
      else
        format.html { render :edit }
        format.json { render json: @typochronological_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /typochronological_units/1
  # DELETE /typochronological_units/1.json
  def destroy
    @typochronological_unit.destroy
    respond_to do |format|
      format.html { redirect_to typochronological_units_url, notice: 'Typochronological unit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_typochronological_unit
      @typochronological_unit = TypochronologicalUnit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def typochronological_unit_params
      params.require(:typochronological_unit).permit(:name, :approx_start_time, :approx_end_time, :parent_id)
    end
end
