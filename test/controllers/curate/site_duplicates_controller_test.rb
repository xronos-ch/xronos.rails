# frozen_string_literal: true

require 'test_helper'

module Curate
  class SiteDuplicatesControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @admin = create(:user, :admin)
      @retained = create(:site, name: 'Sjørup Plantage', country_code: 'DE')
      @source = create(:site, name: 'Sjørup Plantage; site: Sb. 125', country_code: 'DK', lat: 56.419, lng: 9.076)
      @retained_measurement = create_measurement_at(@retained)
      @source_measurement = create_measurement_at(@source)
    end

    test 'shows a candidate pair and merges the selected site fields without merging measurements' do
      sign_in @admin
      get curate_site_duplicates_path

      assert_response :success
      assert_dom "a[href='#{review_path}']", text: 'Compare sites'
      token = review_token

      assert_no_difference ['C14.unscoped.count', 'Context.count', 'Sample.count'] do
        post curate_site_duplicates_path,
             params: { merge: selection(token).merge(sources: { country: @source.id, coordinates: @source.id }) }
      end

      assert_redirected_to site_path(@retained, from: 'site_duplicates')
      assert_equal @retained, @source.reload.ultimately_superseded_by
      assert_equal ['Sjørup Plantage', 'DK'], [@retained.reload.name, @retained.country_code]
      assert_equal [@source.lat, @source.lng], [@retained.lat, @retained.lng]
      assert_includes @retained.site_names.pluck(:name), @source.name
      site_ids = [@retained_measurement, @source_measurement].map { |c14| C14.find(c14.id).site.id }
      assert_equal [@retained.id] * 2, site_ids
      follow_redirect!
      assert_response :success
      assert_dom "a[href='#{curate_site_duplicates_path}']", text: 'Back to site duplicates'

      get site_path(@retained)
      assert_dom 'a', text: 'Back to site duplicates', count: 0
    end

    test 'shows shared and site-specific measurements before merging' do
      sign_in @admin
      context = create(:context, site: @source, name: 'Separate layer')
      unique = create(:c14, sample: create(:sample, context: context), lab_identifier: 'K-500', bp: 4200, std: 40)
      reference = create(:reference, short_ref: 'Layer report', bibtex: nil)
      create(:citation, citing: unique, reference: reference)

      get review_path

      assert_response :success
      assert_dom '#matching-measurements tbody tr', count: 1
      assert_dom "#matching-measurements a[href='#{c14_path(@retained_measurement)}'][target='_blank']"
      assert_dom "#matching-measurements a[href='#{c14_path(@source_measurement)}'][target='_blank']"
      assert_dom "#unmatched-measurements-#{@source.id}" do
        assert_dom "a[href='#{c14_path(unique)}']"
        assert_dom "a[href='#{context_path(context)}']", text: 'Separate layer'
        assert_dom "a[href='#{reference_path(reference)}']", text: 'Layer report'
      end
    end

    test 'merge and next opens the next candidate pair' do
      sign_in @admin
      next_sites = create_list(:site, 2)
      next_sites.each do |site|
        sample = create(:sample, context: create(:context, site: site))
        create(:c14, sample: sample, lab_identifier: 'K-987', bp: 3900, std: 50)
      end
      token = review_token

      post curate_site_duplicates_path, params: { intent: 'next', merge: selection(token) }

      assert_redirected_to curate_site_duplicate_path(next_sites.first, candidate_id: next_sites.last.id)
      assert_equal @retained, @source.reload.ultimately_superseded_by
    end

    test 'the comparison shows site and radiocarbon references under the appropriate site' do
      sign_in @admin
      primary = create(:reference, short_ref: 'Site survey', bibtex: nil)
      measurement = create(:reference, short_ref: 'Radiocarbon report', bibtex: nil)
      create(:citation, citing: @retained, reference: primary)
      create(:citation, citing: @retained_measurement, reference: primary)
      create(:citation, citing: @source_measurement, reference: measurement)

      get review_path

      assert_response :success
      assert_dom "#site-merge-references-panel-#{@retained.id}" do
        assert_dom 'h5', text: 'Cited on the site'
        assert_dom "a[href='#{reference_path(primary)}']", count: 1
        assert_dom "a[href='#{reference_path(measurement)}']", count: 0
      end
      assert_dom "#site-merge-references-panel-#{@source.id}" do
        assert_dom 'h5', text: 'Additional references from radiocarbon measurements'
        assert_dom "a[href='#{reference_path(measurement)}']", count: 1
      end
    end

    test 'the coordinate map receives both existing sites and the custom coordinate inputs' do
      sign_in @admin
      get review_path

      assert_response :success
      assert_dom '[data-site-merge-map-target="container"]'
      assert_dom 'input[data-site-merge-map-target="latitude"]'
      assert_dom 'input[data-site-merge-map-target="longitude"]'
      form = css_select('form[data-controller="site-merge-map"]').sole
      markers = JSON.parse(form['data-site-merge-map-sites-value'])
      assert_equal [@retained, @source].map { |site| [site.lat.to_f, site.lng.to_f] },
                   markers.map { |marker| marker.values_at('lat', 'lng') }
      assert_equal 2, markers.pluck('color').uniq.size
    end

    test 'a curator can enter custom values and keep both original names' do
      sign_in @admin
      token = review_token
      assert_dom 'select[name="merge[sources][name]"] option[value="custom"]'
      assert_dom 'input[name="merge[custom][name]"]'
      values = { name: 'Sjørup Plantage (Sb. 125)', lat: '56.4191', lng: '9.0762', country_code: 'dk' }
      sources = { name: 'custom', coordinates: 'custom', country: 'custom' }

      post curate_site_duplicates_path, params: { merge: selection(token).merge(sources: sources, custom: values) }

      assert_redirected_to site_path(@retained, from: 'site_duplicates')
      assert_equal ['Sjørup Plantage (Sb. 125)', 'DK'], [@retained.reload.name, @retained.country_code]
      assert_equal [BigDecimal('56.4191'), BigDecimal('9.0762')], [@retained.lat, @retained.lng]
      assert_equal ['Sjørup Plantage', @source.name].sort, @retained.site_names.pluck(:name).sort
    end

    test 'invalid coordinates leave the sites intact and preserve the submitted values' do
      sign_in @admin
      token = review_token
      values = { lat: '91', lng: '9.0762' }
      form = selection(token).merge(sources: { coordinates: 'custom' }, custom: values)

      assert_no_difference ['Supersession.count', 'SiteName.count'] do
        post curate_site_duplicates_path, params: { merge: form }
      end

      assert_response :unprocessable_entity
      assert_dom '[role="alert"]', text: /Enter latitude between/
      assert_dom 'input[name="merge[custom][lat]"][value="91"]'
      assert_dom 'select[name="merge[sources][coordinates]"] option[value="custom"][selected]'
      assert_not @source.reload.superseded?
    end

    test 'merging sites with colliding contexts requires confirmation' do
      sign_in @admin
      @source_measurement.context.update!(name: @retained_measurement.context.name)
      token = review_token
      assert_dom 'input[name="merge[confirm_contexts]"][type="checkbox"]'
      assert_dom 'input[type="submit"][value="Merge sites with reviewed contexts"]'

      form = selection(token).merge(sources: { name: 'custom' }, custom: { name: 'Reviewed site name' })
      assert_no_difference ['Supersession.count', 'Context.count'] do
        post curate_site_duplicates_path, params: { merge: form }
      end
      assert_response :unprocessable_entity
      assert_dom '[role="alert"]', text: /Also merge the listed contexts/
      assert_dom 'input[name="merge[custom][name]"][value="Reviewed site name"]'

      assert_difference 'Context.count', -1 do
        post curate_site_duplicates_path, params: { merge: selection(token).merge(confirm_contexts: '1') }
      end
      assert_redirected_to site_path(@retained, from: 'site_duplicates')
      assert_equal @retained_measurement.context, @source_measurement.reload.context
    end

    test 'merging sites with only unnamed contexts offers the required confirmation' do
      sign_in @admin
      @retained_measurement.context.update!(name: nil)
      @source_measurement.context.update!(name: nil)
      token = review_token

      assert_dom 'input[name="merge[confirm_contexts]"][type="checkbox"]'
      assert_dom "details a[href='#{context_path(@retained_measurement.context)}'][target='_blank']"
      assert_dom 'details li', text: /1 radiocarbon measurement/
      assert_dom 'input[value="Merge sites with reviewed contexts"]'
      assert_dom '.alert-warning li', text: /Unnamed context/ do
        assert_dom "a[href='#{context_path(@retained_measurement.context)}']"
        assert_dom "a[href='#{context_path(@source_measurement.context)}']"
      end

      assert_difference 'Context.count', -1 do
        post curate_site_duplicates_path, params: { merge: selection(token).merge(confirm_contexts: '1') }
      end
      assert_redirected_to site_path(@retained, from: 'site_duplicates')
    end

    test 'keeps unnamed contexts separate when the curator names the source context' do
      sign_in @admin
      @retained_measurement.context.update!(name: nil)
      @source_measurement.context.update!(name: nil)
      token = review_token
      form = selection(token).merge(
        separate_contexts: [{ context_id: @retained_measurement.context.id, name: 'Layer from original source' }]
      )

      assert_no_difference 'Context.count' do
        post curate_site_duplicates_path, params: { merge: form }
      end

      assert_redirected_to site_path(@retained, from: 'site_duplicates')
      assert_equal 'Layer from original source', @source_measurement.reload.context.name
      assert_equal @retained.id, @source_measurement.site.id
      assert_nil @retained_measurement.reload.context.name
    end

    test 'conflicting links must be resolved before merging' do
      sign_in @admin
      create(:linked_resource, linkable: @retained, source: 'Wikidata', external_id: 'Q101')
      create(:linked_resource, linkable: @source, source: 'Wikidata', external_id: 'Q102')
      token = review_token
      assert_dom 'input[type="submit"][disabled]'

      assert_no_difference ['Supersession.count', 'LinkedResource.count'] do
        post curate_site_duplicates_path, params: { merge: selection(token) }
      end

      assert_redirected_to review_path
      assert_match(/Resolve the conflicting linked resources/, flash[:alert])
    end

    test 'regular users cannot merge sites' do
      sign_in create(:user)
      post curate_site_duplicates_path, params: { merge: selection('invalid') }

      assert_response :not_found
      assert_not @source.reload.superseded?
    end

    private

    def create_measurement_at(site)
      context = create(:context, site: site)
      sample = create(:sample, context: context)
      create(:c14, sample: sample, lab_identifier: 'K-3247', bp: 4110, std: 85)
    end

    def review_path
      curate_site_duplicate_path(@retained, candidate_id: @source.id)
    end

    def review_token
      get review_path
      assert_response :success
      css_select('input[name="merge[fingerprint]"]').sole['value']
    end

    def selection(token)
      { first_id: @retained.id, second_id: @source.id, target_id: @retained.id, fingerprint: token, keep_names: '1' }
    end
  end
end
