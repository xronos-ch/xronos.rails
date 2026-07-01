# frozen_string_literal: true

##
# Site::FetchDescriptionJob
#
# Pre-warms the +Site::Description+ cache. The controller's lazy turbo-frame
# fetch will hit the warm cache on the first real page visit.
class Site::FetchDescriptionJob < ApplicationJob # rubocop:disable Style/ClassAndModuleChildren
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(site_id)
    site = Site.find_by(id: site_id)
    return unless site
    return unless site.wikidata_link&.approved?

    Site::Description.new(lod_link: site.wikidata_link).data
  end
end
