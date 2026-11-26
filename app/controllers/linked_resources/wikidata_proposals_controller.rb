# frozen_string_literal: true

module LinkedResources
  # Lists current Wikidata suggestions separately from confirmed links.
  class WikidataProposalsController < ApplicationController
    before_action :authenticate_user!
    layout 'curate'

    def index
      authorize! :manage, Site
      proposals = Site::WikidataProposal.for_review.includes(:subject).order(:id)
      @pagy, @proposals = pagy(:offset, proposals)
    end
  end
end
