class C14LabsController < ApplicationController
  load_and_authorize_resource

  before_action :set_c14_lab, only: [:show, :edit, :update, :destroy]

  # GET /c14_labs
  # GET /c14_labs.json
  def index
    @c14_labs = C14Lab.all
  end

  # GET /c14_labs/1
  # GET /c14_labs/1.json
  def show
  end

  # GET /c14_labs/new
  def new
    @c14_lab = C14Lab.new
  end

  # GET /c14_labs/1/edit
  def edit
  end

  # POST /c14_labs
  # POST /c14_labs.json
  def create
    @c14_lab = C14Lab.new(c14_lab_params)

    respond_to do |format|
      if @c14_lab.save
        format.html { redirect_to @c14_lab, notice: 'C14Lab was successfully created.' }
        format.json { render :show, status: :created, location: @c14_lab }
      else
        format.html { render :new }
        format.json { render json: @c14_lab.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /c14_labs/1
  # PATCH/PUT /c14_labs/1.json
  def update
    respond_to do |format|
      if @c14_lab.update(c14_lab_params)
        format.html { redirect_to @c14_lab, notice: 'C14Lab was successfully updated.' }
        format.json { render :show, status: :ok, location: @c14_lab }
      else
        format.html { render :edit }
        format.json { render json: @c14_lab.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /c14_labs/1
  # DELETE /c14_labs/1.json
  def destroy
    @c14_lab.destroy
    respond_to do |format|
      format.html { redirect_to c14_labs_url, notice: 'C14Lab was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_c14_lab
      @c14_lab = C14Lab.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def c14_lab_params
      params.require(:c14_lab).permit(:name, :active)
    end
end