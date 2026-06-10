class XronosData
  include ActiveModel::Model

  # @filters is for UI (what the view reads)
  # @filters_for_query is the mutable copy used to build the AR query
  attr_reader   :filters
  attr_accessor :xrons
  attr_accessor :selects

  def initialize(filters = {}, selects = {})
    self.filters = filters
    @selects     = selects

    @xrons = base_scope
    apply_filters  unless @filters.blank?
    apply_selects  unless @selects.blank?
  end

  # Public: base scope with all rows (no cals join here!)
  def everything
    base_scope
  end

  # ---------------------------
  # Filters
  # ---------------------------

  def filters=(value)
    filters = value.to_h
    filters = deep_compact(filters)
    filters = decode_range_filters(filters)
    filters = decode_array_filters(filters)

    # UI copy (used by filter_value / filter_value_string / sliders)
    @filters = filters

    # Query copy (we can safely mutate this)
    @filters_for_query = @filters.deep_dup
  end

  # Old interface – still works, now just calls the new method
  def filter
    apply_filters
  end

  # ---------------------------
  # Select
  # ---------------------------

  def select
    apply_selects
  end

  def filter_value(*args)
    @filters.dig(*args)
  end

  def filter_value_string(*args)
    vals = @filters.dig(*args)
    vals.join(",") if vals.present?
  end

  # ---------------------------
  # JSON export helper
  # ---------------------------

  def self.store_data_as_json
    query = <<-SQL
      SELECT json_agg(json_build_object('measurement', subquery)) AS measurements
      FROM (SELECT "data_views".* FROM "data_views") subquery
    SQL

    result       = C14.connection.exec_query(query)
    measurements = result[0]["measurements"]

    File.open(Rails.root.join("public", "all_data.json"), "w") do |file|
      file.write(measurements)
    end
  end

  private

  # ---------------------------
  # Base scope (no cals join!)
  # ---------------------------

  def base_scope
    C14
      .left_outer_joins(:c14_lab)
      .left_outer_joins(sample: [
        :material,
        :taxon,
        context: [
          site: [
            :site_types
          ]
        ]
      ])
      .distinct
  end

  # ---------------------------
  # Applying filters and selects
  # ---------------------------

  def apply_filters
    scope         = @xrons
    query_filters = @filters_for_query

    # 1) calibrated age filters – need cals join
    if query_filters.key?(:cals) && query_filters[:cals].present?
      scope = apply_cal_filters(scope, query_filters[:cals])
      query_filters = query_filters.except(:cals)
    end

    # 2) everything else via standard where(...)
    @xrons = scope.where(query_filters)
  end

  def apply_selects
    @xrons = @xrons.select(*@selects).distinct
  end

  # ---------------------------
  # Special handling for cals filters
  # ---------------------------

  def apply_cal_filters(scope, cal_filters)
    scope = scope.joins("JOIN cals ON (cals.c14_age = c14s.bp AND cals.c14_error = c14s.std)")

    # decode_range_filters turns :tpq into an Array of Range objects,
    # normally just [user_tpq..50000]
    if (tpq_ranges = cal_filters[:tpq]).present?
      tpq_ranges = Array(tpq_ranges)
      min_tpq    = tpq_ranges.map { |r| r.respond_to?(:begin) ? r.begin : r }.min
      scope      = scope.where("cals.tpq >= ?", min_tpq)
    end

    # and :taq into [0..user_taq]
    if (taq_ranges = cal_filters[:taq]).present?
      taq_ranges = Array(taq_ranges)
      max_taq    = taq_ranges.map { |r| r.respond_to?(:end) ? r.end : r }.max
      scope      = scope.where("cals.taq <= ?", max_taq)
    end

    scope
  end

  # ---------------------------
  # Filter decoding helpers
  # ---------------------------

  def decode_range_filters(filters)
    # uncal BP slider: we keep your existing behaviour (array of Range)
    if filters.dig(:c14s, :bp).present?
      filters.dig(:c14s, :bp).replace(slice_ranges(filters.dig(:c14s, :bp)))
    end

    if filters.dig(:cals).present?
      # TPQ – user gives a single value; we turn it into [user_tpq..50000]
      tpq_value = filters.dig(:cals, :tpq)
      filters[:cals][:tpq] = slice_ranges([50_000, tpq_value]) if tpq_value

      # TAQ – user gives a single value; we turn it into [0..user_taq]
      taq_value = filters.dig(:cals, :taq)
      filters[:cals][:taq] = slice_ranges([taq_value, 0]) if taq_value
    end

    filters
  end

  # Tom Select encodes multiple values in text inputs as a one-length hash with
  # comma-delimited params, rather than the rails param[] notation.
  def decode_array_filters(filters)
    return filters unless filters.is_a?(Hash)

    filters.transform_values do |val|
      case val
      when Hash
        decode_array_filters(val)
      when Array
        val.map { |v| v.respond_to?(:include?) && v.is_a?(String) && v.include?(",") ? v.split(",") : v }.flatten
      else
        val
      end
    end
  end

  def deep_compact(hash)
    return hash.compact_blank if hash.is_a?(Array)

    hash
      .transform_values { |h| (h.is_a?(Hash) || h.is_a?(Array)) ? deep_compact(h) : h }
      .compact_blank
  end

  def slice_ranges(x)
    x.map! { |i| i.to_i }
    x.each_slice(2).map do |n|
      if n.length == 1
        n[0]..n[0]
      else
        n.sort!
        n[0]..n[1]
      end
    end
  end
end
