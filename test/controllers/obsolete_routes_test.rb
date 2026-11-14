# frozen_string_literal: true

require 'test_helper'

class ObsoleteRoutesTest < ActionDispatch::IntegrationTest
  test 'public data and calibration pages retain their routes' do
    assert_routing '/data', controller: 'xronos_data', action: 'index'
    assert_routing '/c14s/search', controller: 'c14s', action: 'search'
    assert_routing '/c14s/1', controller: 'c14s', action: 'show', id: '1'
  end
end
