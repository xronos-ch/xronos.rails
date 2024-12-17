class LodsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  layout "curate"

  def index
  end

  private

  def lods
    [:issues, :another_allowed_method] # Add all allowed methods here
  end

  def lod_param
    lod = params.fetch(:lod, nil)
    allowed_methods = lods.map(&:to_s)
    return lod.to_sym if lod.present? && allowed_methods.include?(lod)
  end


end
