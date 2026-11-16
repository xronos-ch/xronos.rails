# frozen_string_literal: true

module LinkedResources
  # Enqueues a Wikidata lookup from the linked resources dashboard.
  class WikidataLookupsController < ApplicationController
    before_action :authenticate_user!

    def create
      authorize! :manage, Site
      site = Site.find(params[:site_id])
      Site::WikidataMatchJob.perform_later([site.id])
      redirect_to linked_resources_wikidata_proposals_path, status: :see_other,
                                                            notice: 'Lookup queued. Refresh to see proposals.'
    end
  end
end
