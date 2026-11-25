require 'test_helper'

class Api::V1::DendrosControllerTest < ActionDispatch::IntegrationTest
  test 'visitors can retrieve a paginated collection and an individual series' do
    first = create(:dendro, :anchored)
    second = create(:dendro)

    get '/api/v1/dendros', params: { per_page: 1 }
    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [first.id], payload.fetch('data').pluck('id')
    assert_equal 2, payload.fetch('pagination').fetch('total')
    assert_equal 2, payload.fetch('pagination').fetch('total_pages')

    get '/api/v1/dendros', params: { per_page: 1, page: 2 }
    assert_equal [second.id], JSON.parse(response.body).fetch('data').pluck('id')

    get "/api/v1/dendros/#{first.id}"
    assert_response :success
    record = JSON.parse(response.body)
    assert_equal first.measurements, record.fetch('measurements')
    assert_equal first.site.id, record.fetch('site_id')
    assert_equal first.calendar_start_year, record.fetch('calendar_start_year')
  end

  test 'site and calendar filters select the same records as the data browser' do
    included = create(:dendro, :anchored, anchor_position: 2, anchor_year: 1)
    create(:dendro, :anchored, anchor_year: 100)
    create(:dendro, sample: included.sample, is_anchored: false)

    get '/api/v1/dendros', params: { site_id: included.site.id, calendar_from: 0, calendar_to: 0 }
    assert_response :success
    assert_equal [included.id], JSON.parse(response.body).fetch('data').pluck('id')
  end

  test 'series identifiers and measurement metadata can be filtered' do
    included = create(:dendro, measurement_variable: 'ring_width', measurement_unit: 'mm')
    create(:dendro, measurement_variable: 'latewood_width', measurement_unit: 'µm')

    get '/api/v1/dendros', params: { series_code: included.series_code, measurement_variable: 'ring_width', measurement_unit: 'mm' }
    assert_response :success
    assert_equal [included.id], JSON.parse(response.body).fetch('data').pluck('id')
  end

  test 'invalid queries return a bad request and page sizes are capped' do
    [{ page: 0 }, { page: 'oops' }, { page: '9' * 100 }, { calendar_from: 20, calendar_to: 10 },
     { calendar_to: 'oops' }, { is_anchored: 'maybe' }, { site_id: 'abc' },
     { measurement_variable: 'density' }, { unexpected: 'value' }].each do |query|
      get '/api/v1/dendros', params: query
      assert_response :bad_request
    end

    get '/api/v1/dendros', params: { per_page: 1000 }
    assert_response :success
    assert_equal 100, JSON.parse(response.body).fetch('pagination').fetch('per_page')
  end

  test 'superseded series are excluded and their detail links redirect' do
    canonical = create(:dendro)
    superseded = create(:dendro)
    superseded.merge_into!(canonical)

    get '/api/v1/dendros'
    assert_equal [canonical.id], JSON.parse(response.body).fetch('data').pluck('id')
    get "/api/v1/dendros/#{superseded.id}"
    assert_response :moved_permanently
    assert_redirected_to "/api/v1/dendros/#{canonical.id}"
    get '/api/v1/dendros/0'
    assert_response :not_found
  end
  test 'unknown and floating dating statuses remain distinct in API filters' do
    floating = create(:dendro, is_anchored: false, name: 'FloatingApiNeedle')
    create(:dendro)
    create(:dendro, :anchored)

    get '/api/v1/dendros', params: { is_anchored: 'false', q: 'FloatingApiNeedle' }
    assert_response :success
    record = JSON.parse(response.body).fetch('data').sole
    assert_equal floating.id, record.fetch('id')
    assert_nil record.fetch('calendar_start_year')
  end

end
