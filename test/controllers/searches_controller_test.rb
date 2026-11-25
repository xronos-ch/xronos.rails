# frozen_string_literal: true

require 'test_helper'

class SearchesControllerTest < ActionDispatch::IntegrationTest
  include ControllerSmokeTest

  smoke_tests(
    actions: %i[index],
    statuses: {
      index: { not_signed_in: :success, signed_in: :success }
    }
  )
  test 'global search renders linked dendro cards and filters by type' do
    dendro = create(:dendro, name: 'DendroSearchNeedle')
    get search_path, params: { q: 'DendroSearchNeedle', type: 'Dendro' }
    assert_response :success
    document = Nokogiri::HTML(response.body)
    assert document.at_css("a[href='#{dendro_path(dendro)}']")
    assert document.at_css('article.card')
    assert_not_includes response.body, dendro.measurements.to_s

    get search_path(format: :json), params: { q: 'DendroSearchNeedle', type: 'Dendro' }
    assert_equal [dendro.id], JSON.parse(response.body).pluck('searchable_id')
  end

  test 'stale dendro index entries do not affect result counts or rendering' do
    canonical = create(:dendro, name: 'Retained series')
    old = create(:dendro, name: 'DendroStaleNeedle')
    old.merge_into!(canonical)
    old.pg_search_document.update!(content: 'DendroStaleNeedle')

    get search_path, params: { q: 'DendroStaleNeedle', type: 'Dendro' }
    assert_response :success
    assert_includes response.body, 'No results found'

    get search_path(format: :json), params: { q: 'DendroStaleNeedle', type: 'Dendro' }
    assert_equal [], JSON.parse(response.body)
  end

end
