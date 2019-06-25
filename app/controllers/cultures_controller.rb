class CulturesController < ApplicationController
  load_and_authorize_resource

  before_action :set_culture, only: [:show, :edit, :update, :destroy]

  # GET /cultures
  # GET /cultures.json
  def index
    @cultures = Culture.all
  end

  # GET /cultures/1
  # GET /cultures/1.json
  def show
  end

  # GET /cultures/new
  def new
    @culture = Culture.new
  end

  # GET /cultures/1/edit
  def edit
  end

  # POST /cultures
  # POST /cultures.json
  def create
    @culture = Culture.new(culture_params)

    respond_to do |format|
      if @culture.save
        format.html { redirect_to @culture, notice: 'Culture was successfully created.' }
        format.json { render :show, status: :created, location: @culture }
      else
        format.html { render :new }
        format.json { render json: @culture.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cultures/1
  # PATCH/PUT /cultures/1.json
  def update
    respond_to do |format|
      if @culture.update(culture_params)
        format.html { redirect_to @culture, notice: 'Culture was successfully updated.' }
        format.json { render :show, status: :ok, location: @culture }
      else
        format.html { render :edit }
        format.json { render json: @culture.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cultures/1
  # DELETE /cultures/1.json
  def destroy
    @culture.destroy
    respond_to do |format|
      format.html { redirect_to cultures_url, notice: 'Culture was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_culture
      @culture = Culture.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def culture_params
      params.require(:culture).permit(:name, :approx_start_ime, :approx_end_time)
    end
end
