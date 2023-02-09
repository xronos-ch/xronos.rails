class ReferencesController < ApplicationController
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_reference, only: [:show, :edit, :update, :destroy]

  # GET /references
  # GET /references.json
  def index
    @references = Reference
      .left_joins(:citations)
      .select('"references".*, COUNT(citations.id) AS citations_count')
      .group(:id)
    @pagy, @references = pagy(@references)
  end

  # GET /references/1
  # GET /references/1.json
  def show
    @reference = Reference.find(params[:id])

    @sites = @reference.sites.distinct
    @pagy_sites, @sites = pagy(@sites, page_param: :sites_page)

    @c14s = @reference.c14s.includes([:references, sample: [:material, :taxon, context: [:site] ]])
    @pagy_c14s, @c14s = pagy(@c14s, page_param: :c14s_page)

    @typos = @reference.typos.includes([:references, sample: [ context: [:site] ]])
    @pagy_typos, @typos = pagy(@typos, page_param: :typos_page)
  end

  # GET /references/new
  def new
    @reference = Reference.new
  end

  # GET /references/1/edit
  def edit
  end

  # POST /references
  # POST /references.json
  def create
    @reference = Reference.new(reference_params)

    respond_to do |format|
      if @reference.save
        format.html { redirect_back(fallback_location: @reference, notice: "Reference '#{@reference.short_ref}' was created.") }
        format.json { render :show, status: :created, location: @reference }
      else
        format.html { render :new }
        format.json { render json: @reference.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /references/1
  # PATCH/PUT /references/1.json
  def update
    respond_to do |format|
      if @reference.update(reference_params)
        format.html { redirect_back(fallback_location: @reference, notice: "Reference '#{@reference.short_ref}' was updated.") }
        format.json { render :show, status: :ok, location: @reference }
      else
        format.html { render :edit }
        format.json { render json: @reference.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /references/1
  # DELETE /references/1.json
  def destroy
    deleted_name = @reference.short_ref
    @reference.destroy
    respond_to do |format|
      format.html { redirect_to references_url, notice: "Reference '#{deleted_name}' was deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reference
      @reference = Reference.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def reference_params
      params.require(:reference).permit(:short_ref, :bibtex)
    end
end
