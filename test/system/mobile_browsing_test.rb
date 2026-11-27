# frozen_string_literal: true

require 'application_system_test_case'

class MobileBrowsingTest < ApplicationSystemTestCase
  setup do
    page.driver.browser.execute_cdp(
      'Emulation.setDeviceMetricsOverride',
      width: 320, height: 720, deviceScaleFactor: 1, mobile: true
    )
  end

  teardown do
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end

  test 'the mobile navigation and sign-in form fit above the home hero' do
    visit root_path

    within 'nav.main-nav' do
      find('button[aria-label="Toggle navigation"]').click
      assert_selector '#navbarSupportedContent.show'
      assert_field 'q', type: 'search'
      click_button 'Sign in'
      assert_field 'Email'
      assert_field 'Password'
    end

    assert page.evaluate_script(<<~JS), 'The navigation should fit the viewport and leave the hero below it'
      (() => {
        const nav = document.querySelector("nav.main-nav");
        const form = nav.querySelector(".dropdown-menu.show");
        const hero = document.querySelector(".hero");
        return nav.getBoundingClientRect().bottom <= hero.getBoundingClientRect().top &&
          form.getBoundingClientRect().right <= window.innerWidth;
      })()
    JS
  end

  test 'returning to the data browser clears an open mobile filter drawer' do
    visit root_path
    click_link 'Explore the map', href: data_path
    assert_selector '#dataMap.active .leaflet-container'
    assert_no_selector '#dataFilters', visible: true

    click_button 'Filters'
    within '#dataFilters.show' do
      assert_button 'Filter', exact: true
    end

    page.go_back
    assert_selector 'h1', text: 'Open chronometric data for archaeology'
    page.go_forward
    assert_current_path data_path
    assert_selector '#dataMap.active .leaflet-container'
    assert_no_selector '.offcanvas-backdrop'
    assert_no_selector '#dataFilters', visible: true
    assert page.evaluate_script("getComputedStyle(document.body).overflowY !== 'hidden'")
  end

  test 'the mobile data table shows a record and its ages without horizontal scrolling' do
    material = create(:material, name: 'Material' * 8)
    sample = create(:sample, material: material)
    date = create(:c14, sample: sample, lab_identifier: 'MOBILE-475', bp: 4800, std: 35)

    visit data_path(filter: { c14s: { lab_identifier: [date.lab_identifier] } })
    click_on 'Radiocarbon dates'

    table_region = find('#dataTable [role="region"]')
    within table_region do
      assert_link date.lab_identifier
      assert_text material.name
      assert_text "#{date.bp}±#{date.std}"
      assert_text(/cal BP\s+\d+-\d+/)
    end
    assert table_region.evaluate_script('this.scrollWidth === this.clientWidth'),
           'The radiocarbon table should fit within the mobile viewport'
  end
end
