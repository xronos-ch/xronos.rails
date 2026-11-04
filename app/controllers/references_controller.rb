class ReferencesController < ApplicationController
  include Tabulatable
  include SupersedableController

  load_and_authorize_resource

  before_action :set_reference, only: [:show, :edit, :update, :destroy]

  include MergeableController

  # GET /references
  # GET /references.json
  # GET /references.csv
  def index
    @references = Reference.with_citations_count

    # filter
    unless reference_params.blank?
      @reference_params = reference_params
      @references = @references.where(reference_params)
    end

    # order
    if params.has_key?(:references_order_by)
      order = { params[:references_order_by] => params.fetch(:references_order, "asc") }
      @references = @references.reorder(order)
    end

    respond_to do |format|
      format.html {
        @pagy, @references = pagy(:countish, @references)
      }
      format.json
      format.csv do
        validate_csv_params!
        return if performed?

        # Replace (not append to) the select list, so the template fully
        # controls the exported columns
        @references = @references.reselect(index_csv_template) if index_csv_template
        render csv: @references
      end
    end
  end

  # GET /references/search
  # GET /references/search.json
  def search
    @references = Reference.with_citations_count.search(params[:q])

    # order
    if params.has_key?(:references_order_by)
      order = { params[:references_order_by] => params.fetch(:references_order, "asc") }
      @references = @references.reorder(order)
    end

    respond_to do |format|
      format.html {
        @pagy, @references = pagy(:countish, @references)
        render :index
      }
      format.json  {
        render :index
      }
    end
  end

  # GET /references/1
  # GET /references/1.json
  # GET /references/1.json?schema=csl
  # GET /references/1.bib
  # GET /references/1.yaml
  # GET /references/1.ris
  def show
    # @reference is already set by load_and_authorize_resource + set_reference

    respond_to do |format|
      format.html do
        @citations_count = @reference.citations.count

        @sites = @reference.sites.distinct.with_counts
        @pagy_sites, @sites = pagy(:countish, @sites, page_param: :sites_page)
      end

      format.json do
        if params[:schema] == Reference::CSL_SCHEMA
          send_data JSON.pretty_generate(@reference.csl_items_for_export),
                    type: "application/json; charset=utf-8",
                    filename: "xronos_reference_#{@reference.id}_csl.json",
                    disposition: "attachment"
        end
      end

      format.bibtex do
        send_data @reference.format_bibtex,
                  type: "application/x-bibtex; charset=utf-8",
                  filename: "xronos_reference_#{@reference.id}.bib",
                  disposition: "attachment"
      end

      format.yaml do
        send_data @reference.format_yaml,
                  type: "text/yaml; charset=utf-8",
                  filename: "xronos_reference_#{@reference.id}.yml",
                  disposition: "attachment"
      end

      format.ris do
        send_data @reference.format_ris,
                  type: "application/x-research-info-systems; charset=utf-8",
                  filename: "xronos_reference_#{@reference.id}.ris",
                  disposition: "attachment"
      end
    end
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
      params.fetch(:reference, {}).permit(:short_ref, :revision_comment)
    end
end
