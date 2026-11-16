# frozen_string_literal: true

module LinkedResources
  # Promotes a proposal to an approved linked resource.
  class WikidataApprovalsController < ApplicationController
    before_action :authenticate_user!

    def create
      authorize! :manage, Site
      link = Site::WikidataProposal.accept!(params[:wikidata_proposal_id])
      redirect_to approval_destination(link), status: :see_other, notice: 'Wikidata link approved.'
    rescue Site::WikidataProposal::NoLongerApplicable, ActiveRecord::RecordNotFound,
           ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      redirect_to linked_resources_wikidata_proposals_path, status: :see_other,
                                                            alert: 'This proposal is no longer applicable.'
    end

    private

    def approval_destination(link)
      return site_path(link.linkable, anchor: 'site-external-links') if params[:from] == 'site'

      linked_resources_wikidata_proposals_path
    end
  end
end
