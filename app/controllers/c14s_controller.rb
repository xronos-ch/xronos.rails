class C14sController < ApplicationController
  include C14sHelper

  load_and_authorize_resource

  before_action :set_c14, only: [:show, :edit, :update, :destroy]

  # GET /c14s
  # GET /c14s.json
  def index
    @c14s = C14.all
  end

  # GET /c14s/1
  # GET /c14s/1.json
  def show
    calibrate_from_external(@c14.id)
  end

  # GET /c14s/new
  def new
    @c14 = C14.new
    @c14.build_source_database
  end

  # GET /c14s/1/edit
  def edit
  end

  # POST /c14s
  # POST /c14s.json
  def create
    @c14 = C14.new(c14_params)

    respond_to do |format|
      if @c14.save
        format.html { redirect_to @c14, notice: 'C14 measurement was successfully created.' }
        format.json { render :show, status: :created, location: @c14 }
      else
        format.html { render :new }
        format.json { render json: @c14.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /c14s/1
  # PATCH/PUT /c14s/1.json
  def update
    respond_to do |format|
      if @c14.update(c14_params)
        format.html { redirect_to @c14, notice: 'C14 measurement was successfully updated.' }
        format.json { render :show, status: :ok, location: @c14 }
      else
        format.html { render :edit }
        format.json { render json: @c14.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /c14s/1
  # DELETE /c14s/1.json
  def destroy
    @c14.destroy
    respond_to do |format|
      format.html { redirect_to c14s_url, notice: 'C14 measurement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_c14
      @c14 = C14.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def c14_params
      params.require(:c14).permit(
        :bp,
        :std,
        :cal_bp,
        :cal_std,
        :delta_c13,
        :delta_c13_std,
        :method,
        :source_database_id,
        :source_database_attributes => [
          :id,
          :name,
          :url,
          :citation,
          :licence,
          :_destroy
        ]
      )
    end

end
