class C14::CitationController < ApplicationController
  include CitableController

  private

  def citable_record
    @citable_record ||= C14.find(params[:c14_id])
  end
end
