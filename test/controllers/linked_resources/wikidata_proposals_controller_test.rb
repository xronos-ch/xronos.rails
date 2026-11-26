# frozen_string_literal: true

require 'test_helper'

module LinkedResources
  class WikidataProposalsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ActiveJob::TestHelper

    setup do
      @site = create(:site, name: 'Deer’s Den')
      @proposal = @site.curation_proposals.create!(kind: Site::WikidataProposal::KIND, target_key: 'Q42',
                                                   evidence: { site_name: @site.name, label: 'Deer’s Den' })
      @wikidata = stub_request(:get, %r{\Ahttps://query\.wikidata\.org/sparql})
    end

    test 'review pages do not look up Wikidata and an admin can explicitly queue a lookup' do
      get site_path(@site)
      assert_response :success
      assert_dom 'a[href*="/wiki/Q42"]', count: 0
      sign_in create(:user, :admin)
      get linked_resources_sites_path
      assert_response :success
      assert_dom "form[action='#{linked_resources_site_wikidata_lookup_path(@site)}']"
      get linked_resources_wikidata_proposals_path
      assert_response :success
      assert_dom 'td', text: /Exact English name match/

      assert_enqueued_with(job: Site::WikidataMatchJob, args: [[@site.id]]) do
        post linked_resources_site_wikidata_lookup_path(@site)
      end
      assert_redirected_to linked_resources_wikidata_proposals_path
      assert_not_requested @wikidata
    end

    test 'approval creates the confirmed link and removes the reviewed proposal' do
      sign_in create(:user, :admin)
      assert_difference 'LinkedResource.count', 1 do
        assert_difference 'CurationProposal.count', -1 do
          post linked_resources_wikidata_proposal_approval_path(@proposal)
        end
      end

      assert_redirected_to linked_resources_wikidata_proposals_path
      assert_equal 'Q42', @site.wikidata_link.external_id
      assert @site.wikidata_link.approved?
      assert_not_requested @wikidata
    end

    test 'a curator can approve a proposal from the site page and return to its linked data' do
      sign_in create(:user, :admin)

      get site_path(@site)
      assert_response :success
      assert_dom '#site-wikidata-proposals a[href*="/wiki/Q42"]'
      approval_path = linked_resources_wikidata_proposal_approval_path(@proposal)
      assert_dom "#site-wikidata-proposals form[action='#{approval_path}']"
      assert_dom 'a', text: 'Add Wikidata link'

      post linked_resources_wikidata_proposal_approval_path(@proposal), params: { from: 'site' }

      assert_redirected_to site_path(@site, anchor: 'site-external-links')
      assert @site.wikidata_link.approved?
      follow_redirect!
      assert_response :success
      assert_dom '#site-wikidata-proposals', count: 0
      assert_not_requested @wikidata
    end

    test 'a regular account cannot approve a proposal' do
      sign_in create(:user)
      get site_path(@site)
      assert_response :success
      assert_dom '#site-wikidata-proposals', count: 0
      assert_no_difference 'LinkedResource.count' do
        post linked_resources_wikidata_proposal_approval_path(@proposal)
      end

      assert_response :not_found
    end

    test 'a proposal based on an earlier site name cannot be approved' do
      sign_in create(:user, :admin)
      @site.update!(name: 'Another site')
      get linked_resources_wikidata_proposals_path
      assert_response :success
      assert_dom 'p', text: 'No current Wikidata proposals.'
      assert_no_difference 'LinkedResource.count' do
        post linked_resources_wikidata_proposal_approval_path(@proposal)
      end

      assert_redirected_to linked_resources_wikidata_proposals_path
    end
  end
end
