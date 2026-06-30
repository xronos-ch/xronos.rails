# frozen_string_literal: true

class Sites::DescriptionsController < ApplicationController # rubocop:disable Style/ClassAndModuleChildren
  def show
    @site = Site.find(params[:site_id])
    @description = Site::Description.new(lod_link: @site.wikidata_link)
    render partial: 'sites/descriptions/site_description',
           locals: { description: @description, site: @site }
  end
end
