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

  test 'search excludes superseded and missing records and includes restored records' do
    query = 'searchregression'
    active = create(:site, name: "#{query} active")
    superseded = create(:site, name: "#{query} superseded")
    superseded.supersede!(active)
    missing = create(:site, name: "#{query} missing")
    missing.delete

    get search_path, params: { q: query, type: 'Site' }

    assert_response :success
    page = Nokogiri::HTML(response.body)
    headings = page.css('article.card h1').map { |heading| heading.text.strip }
    assert_equal [active.name], headings
    assert_equal '1', page.at_css('.nav-link.active .badge').text

    get search_path(format: :json), params: { q: query }
    assert_response :success
    result_ids = response.parsed_body.pluck('searchable_id')
    assert_equal [active.id], result_ids

    PaperTrail.request(whodunnit: create(:user).id.to_s) { superseded.restore! }
    get search_path, params: { q: query }

    assert_response :success
    page = Nokogiri::HTML(response.body)
    headings = page.css('article.card h1').map { |heading| heading.text.strip }
    assert_equal [active.name, superseded.name].sort, headings.sort
    assert_equal '2', page.at_css('.nav-link.active .badge').text
  end
end
