class TyposController < ApplicationController
  include Tabulatable

  load_and_authorize_resource

  before_action :set_typo, only: [:show, :edit, :update, :destroy]

  # GET /typos
  # GET /typos.json
  # GET /typos.csv
  def index
    @typos = Typo.includes(
      :references,
      sample: [
        { context: :site }
      ]
    )

    # filter
    unless typo_params.blank?
      @typo_params = typo_params
      @typos = @typos.where(typo_params)
    end

    respond_to do |format|
      format.html do
        # Sorting is only applied to the interactive HTML table.
        # CSV exports deliberately ignore arbitrary ordering parameters.
        if params.has_key?(:typos_order_by)
          order = { params[:typos_order_by] => params.fetch(:typos_order, "asc") }
          @typos = @typos.reorder(order)
        end

        begin
          @pagy, @typos = pagy(:countish, @typos)
        rescue Pagy::OverflowError
          head :not_found
        end
      end

      format.json

      format.csv do
        # Public CSV export remains available, but does not honour pagination
        # or arbitrary sorting parameters from crawlers/bots.
        @typos = @typos.reorder(:id).select(index_csv_template)
        render csv: @typos
      end
    end
  end

  # GET /typos/search
  # GET /typos/search.json
  def search
    @typos = Typo.search(params[:q])

    respond_to do |format|
      format.html do
        begin
          @pagy, @typos = pagy(:countish, @typos)
        rescue Pagy::OverflowError
          head :not_found
        end

        render :index unless performed?
      end

      format.json do
        render :index
      end
    end
  end

  # GET /typos/1
  # GET /typos/1.json
  def show
  end

  # GET /typos/new
  def new
    @typo = Typo.new
  end

  # GET /typos/1/edit
  def edit
  end

  # POST /typos
  # POST /typos.json
  def create
    @typo = Typo.new(typo_params)

    respond_to do |format|
      if @typo.save
        format.html { redirect_to @typo, notice: "Typo was successfully created." }
        format.json { render :show, status: :created, location: @typo }
      else
        format.html { render :new }
        format.json { render json: @typo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /typos/1
  # PATCH/PUT /typos/1.json
  def update
    respond_to do |format|
      if @typo.update(typo_params)
        format.html { redirect_to @typo, notice: "Typo was successfully updated." }
        format.json { render :show, status: :ok, location: @typo }
      else
        format.html { render :edit }
        format.json { render json: @typo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /typos/1
  # DELETE /typos/1.json
  def destroy
    @typo.destroy

    respond_to do |format|
      format.html { redirect_to typos_url, notice: "Typo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_typo
    @typo = Typo.find(params[:id])
  end

  def typo_params
    params.fetch(:typo, {}).permit(
      :name,
      :approx_start_time,
      :approx_end_time,
      :sample_id,
      sample: [
        :context_id,
        contexts: [
          :site_id
        ]
      ]
    )
  end
end
