# frozen_string_literal: true

require 'test_helper'

class IconHelperTest < ActionView::TestCase
  test 'Bootstrap icons use inline SVG and preserve caller attributes' do
    options = { class: 'me-2', title: 'Download' }
    svg = Nokogiri::HTML.fragment(bs_icon('download', options)).at_css('svg')

    assert svg
    assert_equal 'app-icon me-2', svg['class']
    assert_equal 'Download', svg['aria-label']
    assert svg.at_css('path')
    assert_equal 'me-2', options[:class]
  end

  test 'XRONOS and Simple Icons use the common SVG class' do
    xronos = Nokogiri::HTML.fragment(xr_icon(Site, { light: true }, { alt: '' })).at_css('svg')
    simple = Nokogiri::HTML.fragment(simple_icon('zenodo')).at_css('svg')

    assert_equal 'true', xronos['aria-hidden']
    assert_equal 'app-icon', xronos['class']
    assert_equal 'app-icon simple-icon', simple['class']
    assert_equal 'Zenodo', simple['aria-label']
  end
end
