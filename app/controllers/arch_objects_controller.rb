class ArchObjectsController < ApplicationController
  before_action :set_arch_object, only: [:show, :edit, :update, :destroy]

  # GET /arch_objects
  # GET /arch_objects.json
  def index
    @arch_objects = ArchObject.all
  end

  # GET /arch_objects/1
  # GET /arch_objects/1.json
  def show
  end

  # GET /arch_objects/new
  def new
    @arch_object = ArchObject.new
  end

  # GET /arch_objects/1/edit
  def edit
  end

  # POST /arch_objects
  # POST /arch_objects.json
  def create
    @arch_object = ArchObject.new(arch_object_params)

    respond_to do |format|
      if @arch_object.save
        format.html { redirect_to @arch_object, notice: 'Arch object was successfully created.' }
        format.json { render :show, status: :created, location: @arch_object }
      else
        format.html { render :new }
        format.json { render json: @arch_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /arch_objects/1
  # PATCH/PUT /arch_objects/1.json
  def update
    respond_to do |format|
      if @arch_object.update(arch_object_params)
        format.html { redirect_to @arch_object, notice: 'Arch object was successfully updated.' }
        format.json { render :show, status: :ok, location: @arch_object }
      else
        format.html { render :edit }
        format.json { render json: @arch_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /arch_objects/1
  # DELETE /arch_objects/1.json
  def destroy
    @arch_object.destroy
    respond_to do |format|
      format.html { redirect_to arch_objects_url, notice: 'Arch object was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_arch_object
      @arch_object = ArchObject.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def arch_object_params
      params.require(:arch_object).permit(:site_id, :material_id, :species_id)
    end
end
