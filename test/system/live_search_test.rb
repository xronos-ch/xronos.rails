# frozen_string_literal: true

require 'application_system_test_case'

class LiveSearchTest < ApplicationSystemTestCase
  test 'typing updates the full results and keeps the selected record type' do
    initial = create(:site, name: 'liveinitial')
    match = create(:site, name: 'liveupdated')
    create(:reference, short_ref: match.name)

    visit search_path(q: initial.name, type: 'Site')

    within('form[aria-label="Search records"]') { fill_in 'q', with: match.name }

    within 'turbo-frame#search_results' do
      assert_selector 'article.card h1', text: match.name, exact_text: true
      assert_no_selector 'article.card h1', text: initial.name
      assert_selector '.nav-link.active .badge', exact_text: '1'
      assert_selector 'article.card', count: 1
    end
    assert_current_path search_path(q: match.name, type: 'Site')
  end
end
