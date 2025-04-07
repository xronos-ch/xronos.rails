class C14LabsController < ApplicationController
  include Pagy::Backend
  include Tabulatable

  load_and_authorize_resource

  before_action :set_c14_lab, only: [:show, :edit, :update, :destroy]

  # GET /c14_labs
  # GET /c14_labs.json
  # GET /c14_labs.csv
  def index
    @c14_labs = C14Lab.all
    respond_to do |format|
      format.html {
        @pagy, @c14_labs = pagy(@c14_labs)
      }
      format.csv {
        @c14_labs = @c14_labs.select(index_csv_template)
        render csv: @c14_labs
      }
    end
  end

  # GET /c14_labs/1
  # GET /c14_labs/1.json
  def show
    @c14s = @c14_lab.c14s
    respond_to do |format|
      format.html {
        @pagy_c14s, @c14s = pagy(@c14s, page_param: :c14s_page)
      }
      format.json
    end
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
        format.html { redirect_back(fallback_location: @c14_lab, notice: "Created #{@c14_lab.name}.") }
        format.json { render :show, status: :created, location: @c14_lab }
      else
        format.html { render :new }
        format.json { render json: @c14_lab.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /c14_labs/1
  # PATCH/PUT /c14_labs/1.json
  def update
    respond_to do |format|
      if @c14_lab.update(c14_lab_params)
        format.html { redirect_back(fallback_location: @c14_lab, notice: "Saved changes to #{@c14_lab.name}.") }
        format.json { render :show, status: :ok, location: @c14_lab }
      else
        format.html { render :edit }
        format.json { render json: @c14_lab.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /c14_labs/1
  # DELETE /c14_labs/1.json
  def destroy
    deletedName = @c14_lab.name
    @c14_lab.destroy
    respond_to do |format|
      format.html { redirect_to c14_labs_url, notice: "#{deletedName} was deleted." }
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
