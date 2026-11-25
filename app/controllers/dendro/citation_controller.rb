class Dendro::CitationController < ApplicationController
  include CitableController

  private

  def citable_record
    @citable_record ||= Dendro.unscoped.find(params[:dendro_id]).ultimately_superseded_by
  end
end
