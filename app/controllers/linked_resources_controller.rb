class LinkedResourcesController < ApplicationController
  load_and_authorize_resource

  before_action :set_linked_resource, only: %i[show edit update destroy]

  def show
    render partial: 'linked_resource', locals: { linked_resource: @linked_resource }
  end

  def new
    source = params.dig(:linked_resource, :source)
    head :bad_request and return unless source.present? && LinkedResource::Source.known?(source)

    @linked_resource = LinkedResource.new(linked_resource_params_from_query)
  end

  def edit; end

  def create
    @linked_resource = LinkedResource.new(linked_resource_params)

    respond_to do |format|
      if @linked_resource.save
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :created, location: @linked_resource }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @linked_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @linked_resource.update(linked_resource_params)
        format.html { redirect_back fallback_location: root_path, notice: success_notice }
        format.json { render :show, status: :ok, location: @linked_resource }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @linked_resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    linkable = @linked_resource.linkable
    @linked_resource.destroy
    respond_to do |format|
      format.turbo_stream do
        if linkable.linked_resources.count.positive?
          render turbo_stream: turbo_stream.remove(@linked_resource)
        else
          render turbo_stream: turbo_stream.replace(
            'site-external-links-content',
            partial: 'sites/external_links',
            locals: { site: linkable }
          )
        end
      end
      format.html { redirect_to linkable, notice: "#{@linked_resource.source} link removed.", status: :see_other }
    end
  end

  private

  def set_linked_resource
    @linked_resource = LinkedResource.find(params[:id])
  end

  def linked_resource_params
    params.require(:linked_resource).permit(
      :external_id,
      :source,
      :linkable_type,
      :linkable_id,
      :status
    )
  end

  def success_notice
    "#{@linked_resource.linkable_type}:#{@linked_resource.linkable_id} " \
      "is now linked to #{@linked_resource.source} #{@linked_resource.external_id}"
  end

  def linked_resource_params_from_query
    params.fetch(:linked_resource, {}).permit(:linkable_type, :linkable_id, :source)
  end
end
