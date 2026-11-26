# frozen_string_literal: true

require 'test_helper'

class SearchPreviewsControllerTest < ActionDispatch::IntegrationTest
  test 'the preview links to each supported result type and to the full search' do
    query = 'previewmatch'
    site = create(:site, name: query)
    date = create(:c14, lab_identifier: "#{query}-123")
    reference = create(:reference, short_ref: "#{query} 2025")

    get search_preview_path, params: { q: query }

    assert_response :success
    links = preview_links
    assert_includes links.fetch(site_path(site), ''), site.name
    assert_includes links.fetch(c14_path(date), ''), date.lab_identifier
    assert_includes links.fetch(reference_path(reference), ''), reference.short_ref
    assert_equal 'View all results', links[search_path(q: query)]
    refute_match(/<!doctype html/i, response.body)
  end

  test 'the preview limits visible results and omits stale index entries' do
    query = 'previewlimit'
    active = create(:site, name: query)
    superseded = create(:site, name: "#{query} replaced")
    superseded.supersede!(active)
    PgSearch::Document.create!(searchable: superseded, content: query)
    missing = create(:site, name: "#{query} missing")
    missing.delete
    6.times { |index| create(:site, name: "#{query} #{index}") }

    get search_preview_path, params: { q: query }

    assert_response :success
    links = preview_links('li a')
    assert_equal 6, links.size
    assert_includes links.keys, site_path(active)
    assert_not_includes links.keys, site_path(superseded)
    assert_not_includes links.keys, site_path(missing)
  end

  test 'the preview still links to the full search when no records match' do
    query = 'nosuchpreviewresult'
    get search_preview_path, params: { q: query }

    assert_response :success
    assert_empty preview_links('li a')
    assert_includes response.body, 'No results found.'
    assert_equal 'View all results', preview_links[search_path(q: query)]
  end

  test 'a short query returns no preview' do
    get search_preview_path, params: { q: ' ab ' }

    assert_response :no_content
  end

  private

  def preview_links(selector = 'a')
    Nokogiri::HTML.fragment(response.body).css(selector).to_h { |link| [link['href'], link.text.strip] }
  end
end
