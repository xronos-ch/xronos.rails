class SiteNamesController < ApplicationController
  before_action :set_site
  before_action :set_site_name, only: [:edit, :update, :destroy]

  def new
    @site_name = SiteName.new(site: @site)
  end

  def create
    @site_name = @site.site_names.build(site_name_params)

    if @site_name.save
      respond_to do |format|
        format.html { redirect_to @site, notice: "Site alias added." }
        format.turbo_stream { flash.now[:notice] = "Site alias added." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site_name.update(site_name_params)
      redirect_to @site, notice: "Site alias updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site_name.destroy

    respond_to do |format|
      format.html { redirect_to @site, notice: "Site alias removed." }
      format.turbo_stream { flash.now[:notice] = "Site alias removed." }
    end
  end

  private

  def site_name_params
    params.require(:site_name).permit(:language, :name)
  end

  def set_site
    @site = Site.find(params[:site_id])
  end

  def set_site_name
    @site_name = @site.site_names.find(params[:id])
  end

end
