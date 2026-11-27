# frozen_string_literal: true

require 'json'

# Natural Earth's WGS84 GeoJSON layers. The coastline layer provides the
# shoreline independently of the artificial edges in the ocean polygons.
class NaturalEarthWater
  EARTH_RADIUS_METERS = 6_371_009
  RADIANS_PER_DEGREE = Math::PI / 180

  # A polygon ring indexed by latitude for ray-crossing tests.
  class Ring
    def initialize(coordinates)
      @west, @east = coordinates.map(&:first).minmax
      @edges_by_latitude = Hash.new { |hash, latitude| hash[latitude] = [] }
      coordinates.each_cons(2) { |first, last| index_edge(first, last) }
    end

    def includes?(lng, lat)
      return false unless lng.between?(@west, @east)

      @edges_by_latitude.fetch(lat.floor, []).count do |(x1, y1), (x2, y2)|
        (y1 > lat) != (y2 > lat) && lng < x1 + ((x2 - x1) * (lat - y1) / (y2 - y1))
      end.odd?
    end

    private

    def index_edge(first, last)
      low, high = [first[1], last[1]].minmax
      return if low == high

      (low.floor..high.floor).each { |latitude| @edges_by_latitude[latitude] << [first, last] }
    end
  end

  def initialize(directory)
    @directory = directory
    ocean = load_shapes('ocean', 'Polygon')
    lakes = load_shapes('lakes', 'Polygon')
    @polygons = (ocean + lakes).map { |polygon| polygon.map { |ring| Ring.new(ring) } }
    load_shorelines(load_shapes('coastline', 'LineString') + lakes.flatten(1))
  end

  def distance_to_shore(lng, lat)
    lng = lng.to_f
    lat = lat.to_f
    return unless water?(lng, lat)

    squared_distance = nearest_shoreline(unit_vector(lng, lat))
    2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(squared_distance) / 2)
  end

  private

  def load_shorelines(lines)
    @shorelines = lines.flat_map do |line|
      vectors = line.map { |lng, lat| unit_vector(lng, lat) }
      vectors.each_cons(2).each_slice(64).map { |edges| [edges, edge_bounds(edges)] }
    end
  end

  def edge_bounds(edges)
    # Every arc lies inside the bounds of its chord, expanded by its sagitta.
    padding = edges.map { |first, last| arc_padding(first, last) }.max
    edges.flatten(1).transpose.map do |axis|
      low, high = axis.minmax
      (low - padding)..(high + padding)
    end
  end

  def arc_padding(first, last)
    1 - Math.sqrt((1 + dot(first, last).clamp(-1, 1)) / 2)
  end

  def nearest_shoreline(point)
    best = 4.0
    @shorelines.each do |edges, bounds|
      next if box_distance_squared(point, bounds) >= best

      edges.each { |first, last| best = [best, arc_distance_squared(point, first, last)].min }
    end
    best
  end

  def load_shapes(layer, type)
    path = File.join(@directory, "ne_10m_#{layer}.geojson")
    features = JSON.parse(File.read(path)).fetch('features')
    shapes = features.flat_map { |feature| parts(feature.fetch('geometry'), type) }
    raise ArgumentError, "Empty reference layer in #{path}" if shapes.empty?

    shapes
  end

  def parts(geometry, type)
    case geometry.fetch('type')
    when type then [geometry.fetch('coordinates')]
    when "Multi#{type}" then geometry.fetch('coordinates')
    else raise ArgumentError, "Expected #{type} or Multi#{type}"
    end
  end

  def water?(lng, lat)
    return inside_water_polygon?(lng, lat) if lng.abs != 180

    inside_water_polygon?(180.0.prev_float, lat) || inside_water_polygon?(-180.0.next_float, lat)
  end

  def inside_water_polygon?(lng, lat)
    @polygons.any? do |shell, *holes|
      shell.includes?(lng, lat) && holes.none? { |hole| hole.includes?(lng, lat) }
    end
  end

  def unit_vector(lng, lat)
    lng *= RADIANS_PER_DEGREE
    lat *= RADIANS_PER_DEGREE
    [Math.cos(lat) * Math.cos(lng), Math.cos(lat) * Math.sin(lng), Math.sin(lat)]
  end

  def box_distance_squared(point, bounds)
    point.zip(bounds).sum { |value, range| (value - value.clamp(range.begin, range.end))**2 }
  end

  def arc_distance_squared(point, first, last)
    # Project onto the great circle, then use an endpoint if the nearest
    # position on the circle falls outside this shoreline segment.
    segment_dot = dot(first, last).clamp(-1, 1)
    first_dot = dot(point, first)
    last_dot = dot(point, last)
    chord_distance_squared(nearest_arc_dot(segment_dot, first_dot, last_dot))
  end

  def nearest_arc_dot(segment, first, last)
    return [first, last].max if segment.abs == 1 || last <= segment * first || first <= segment * last

    tangent = (last - segment * first) / Math.sqrt(1 - segment * segment)
    Math.hypot(first, tangent)
  end

  def chord_distance_squared(dot_product)
    2 * (1 - dot_product.clamp(-1, 1))
  end

  def dot(left, right)
    left[0] * right[0] + left[1] * right[1] + left[2] * right[2]
  end
end
