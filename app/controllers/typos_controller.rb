class TyposController < ApplicationController
  include Tabulatable
  include Pagy::Backend

  load_and_authorize_resource

  before_action :set_typo, only: [:show, :edit, :update, :destroy]

  # GET /typos
  # GET /typos.json
  # GET /typos.csv
  def index
    @typos = Typo.includes([
      :references, 
      sample: [ 
        context: [ 
          :site 
        ] 
      ] 
    ])

    # filter
    unless typo_params.blank?
      @typos = @typos.where(typo_params)
    end

    # order
    if params.has_key?(:typos_order_by)
      order = { params[:typos_order_by] => params.fetch(:typos_order, "asc") }
      @typos = @typos.reorder(order)
    end

    respond_to do |format|
      format.html { 
        @pagy, @typos = pagy(@typos)
      }
      format.json
      format.csv {
        @typos = @typos.select(index_csv_template)
        render csv: @typos
      }
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
        format.html { redirect_to @typo, notice: 'Typo was successfully created.' }
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
        format.html { redirect_to @typo, notice: 'Typo was successfully updated.' }
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
      format.html { redirect_to typos_url, notice: 'Typo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_typo
      @typo = Typo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
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
