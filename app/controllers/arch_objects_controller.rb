class ArchObjectsController < ApplicationController
  load_and_authorize_resource

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
    @arch_object.samples.build.measurements.build
    @arch_object.samples.each { |sample| sample.measurements.each { |measurement| measurement.build_c14_measurement.build_source_database } }
    @arch_object.samples.each { |sample| sample.measurements.each { |measurement| measurement.build_lab } }
    @arch_object.build_site_phase.build_site_type
    @arch_object.site_phase.build_site
    @arch_object.build_material
    @arch_object.build_species
    @arch_object.build_on_site_object_position
    @arch_object.on_site_object_position.build_feature_type
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
      params.require(:arch_object).permit(
        :id,
        :site_phase_id,
        :material_id,
        :species_id,
        :on_site_object_position_id,
        :_destroy,
        :site_phase_attributes => [
          :id,
          :name,
          :approx_start_time,
          :approx_end_time,
          :site_id,
          :site_type_id,
          :_destroy,
          :site_attributes => [
            :id,
            :name,
            :lat,
            :lng,
            :_destroy,
            :country_id,
            :country_attributes => [
              :id,
              :name,
              :_destroy
            ],
            :fell_phases_attributes => [
              :id,
              :name,
              :start_time,
              :end_time,
              :_destroy,
              :references_attributes => [
                :id,
                :short_ref,
                :bibtex,
                :_destroy
              ]
            ]
          ],
          :site_type_attributes => [
            :id,
            :name,
            :description,
            :_destroy
          ],
          :periods_attributes => [
            :id,
            :parent_id,
            :name,
            :approx_start_time,
            :approx_end_time,
            :_destroy
          ],
          :typochronological_units_attributes => [
              :id,
              :parent_id,
              :name,
              :approx_start_time,
              :approx_end_time,
              :_destroy
          ],
          :ecochronological_units_attributes => [
              :id,
              :parent_id,
              :name,
              :approx_start_time,
              :approx_end_time,
              :_destroy
          ]
        ],
        :material_attributes => [
          :id,
          :name,
          :_destroy
        ],
        :species_attributes => [
          :id,
          :name,
          :_destroy
        ],
        :on_site_object_position_attributes => [
          :id,
          :feature,
          :site_grid_square,
          :coord_reference_system,
          :coord_X,
          :coord_Y,
          :coord_Z,
          :_destroy,
          :feature_type_id,
          :feature_type_attributes => [
            :id,
            :name,
            :description,
            :_destroy
          ]
        ],
        :samples_attributes => [
          :id,
          :_destroy,
          :measurements_attributes => [
            :id,
            :labnr,
            :sample_id,
            :lab_id,
            :c14_measurement_id,
            :_destroy,
            :c14_measurement_attributes => [
              :id,
              :bp,
              :std,
              :cal_bp,
              :cal_std,
              :delta_c13,
              :delta_c13_std,
              :method,
              :_destroy,
              :source_database_id,
              :source_database_attributes => [
                :id,
                :name,
                :url,
                :citation,
                :licence,
                :_destroy
              ]
            ],
            :lab_attributes => [
              :id,
              :name,
              :active,
              :_destroy
            ],
            :references_attributes => [
              :id,
              :short_ref,
              :bibtex,
              :_destroy
            ]
          ]
        ]
      )
    end
end
