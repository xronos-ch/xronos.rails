class LodsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  layout "curate"

  def index
  end

  private

  def lods
    # override, e.g. Site.issues
  end

  def lod_param
    lod = params.fetch(:lod, nil)
    return lod if lod.present? and lod.in?(lods.to_s)
  end


end
