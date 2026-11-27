# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require 'tmpdir'
require_relative '../../../lib/natural_earth_water'

class WaterReferenceTest < Minitest::Test
  def test_water_uses_shorelines_and_respects_islands
    with_reference do |reference|
      assert_nil reference.distance_to_shore(1, 5)
      assert_nil reference.distance_to_shore(7, 7)
      assert_in_delta 111_000, reference.distance_to_shore(-1, 0), 300
      assert_in_delta 22_100, reference.distance_to_shore(6.2, 7), 300
    end
  end

  def test_distance_across_the_antimeridian
    with_reference do |reference|
      assert_in_delta 111_200, reference.distance_to_shore(179.5, 0), 300
      assert_in_delta 55_600, reference.distance_to_shore(-180, 0), 150
    end
  end

  private

  def with_reference
    Dir.mktmpdir do |dir|
      write_feature(dir, 'ocean', 'MultiPolygon', ocean_polygons)
      write_feature(dir, 'lakes', 'Polygon', lake_with_island)
      write_feature(dir, 'coastline', 'MultiLineString', [[[0, -10], [0, 10]], [[-179.5, -10], [-179.5, 10]]])
      yield NaturalEarthWater.new(dir)
    end
  end

  def ocean_polygons
    [
      [[[-10, -10], [0, -10], [0, 10], [-10, 10], [-10, -10]]],
      [[[170, -10], [180, -10], [180, 10], [170, 10], [170, -10]]]
    ]
  end

  def lake_with_island
    [
      [[6, 6], [8, 6], [8, 8], [6, 8], [6, 6]],
      [[6.5, 6.5], [6.5, 7.5], [7.5, 7.5], [7.5, 6.5], [6.5, 6.5]]
    ]
  end

  def write_feature(dir, layer, type, coordinates)
    feature = { type: 'Feature', geometry: { type: type, coordinates: coordinates } }
    File.write(File.join(dir, "ne_10m_#{layer}.geojson"),
               JSON.generate(type: 'FeatureCollection', features: [feature]))
  end
end
