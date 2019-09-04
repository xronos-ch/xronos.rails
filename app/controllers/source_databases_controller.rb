class SourceDatabasesController < ApplicationController
  load_and_authorize_resource

  before_action :set_source_database, only: [:show, :edit, :update, :destroy]

  # GET /source_databases
  # GET /source_databases.json
  def index
    @source_databases = SourceDatabase.all
  end

  # GET /source_databases/1
  # GET /source_databases/1.json
  def show
  end

  # GET /source_databases/new
  def new
    @source_database = SourceDatabase.new
  end

  # GET /source_databases/1/edit
  def edit
  end

  # POST /source_databases
  # POST /source_databases.json
  def create
    @source_database = SourceDatabase.new(source_database_params)

    respond_to do |format|
      if @source_database.save
        format.html { redirect_to @source_database, notice: 'Source database was successfully created.' }
        format.json { render :show, status: :created, location: @source_database }
      else
        format.html { render :new }
        format.json { render json: @source_database.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /source_databases/1
  # PATCH/PUT /source_databases/1.json
  def update
    respond_to do |format|
      if @source_database.update(source_database_params)
        format.html { redirect_to @source_database, notice: 'Source database was successfully updated.' }
        format.json { render :show, status: :ok, location: @source_database }
      else
        format.html { render :edit }
        format.json { render json: @source_database.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /source_databases/1
  # DELETE /source_databases/1.json
  def destroy
    @source_database.destroy
    respond_to do |format|
      format.html { redirect_to source_databases_url, notice: 'Source database was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source_database
      @source_database = SourceDatabase.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def source_database_params
      params.require(:source_database).permit(:name, :url, :citation, :licence)
    end
end
