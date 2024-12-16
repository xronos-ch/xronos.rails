class XronosData
  include ActiveModel::Model

  attr_accessor :xrons, :filters, :selects, :data_type

  def initialize(filters = {}, selects = {}, data_type = :c14)
    raise ArgumentError, "data_type must be :c14 or :dendro" unless %i[c14 dendro].include?(data_type)
    
    self.filters = filters
    @selects = selects
    @data_type = data_type

    @xrons = fetch_data
    apply_filters
    apply_selects
  end

  # Fetch the base data based on data_type
    def fetch_data
      case @data_type
      when :c14
        Chron.fetch_c14
      when :dendro
        Chron.fetch_dendro
      else
        raise ArgumentError, "Unsupported data_type: #{@data_type}"
      end
    end
    
    def everything
      fetch_data
    end

  # Assign and process filters
  def filters=(value)
    @filters = process_filters(value.to_h)
  end

  # Apply filters to the query
  def apply_filters
    @xrons = @xrons.where(@filters) if @filters.present?
  end

  # Apply selections to the query
  def apply_selects
    @xrons = @xrons.select(*@selects).distinct if @selects.present?
  end

  # Access specific filter values
  def filter_value(*keys)
    @filters.dig(*keys)
  end

  def filter_value_string(*keys)
    Array(@filters.dig(*keys)).join(",") if @filters.dig(*keys).present?
  end

  # Store data as JSON for export
  def self.store_data_as_json
    query = <<~SQL
      SELECT json_agg(json_build_object('measurement', subquery)) AS measurements
      FROM (SELECT "data_views".* FROM "data_views") subquery
    SQL

    result = C14.connection.exec_query(query)
    measurements = result[0]['measurements']

    File.write(Rails.root.join('public', 'all_data.json'), measurements)
  end

  private

  # Process filters by compacting and decoding
  def process_filters(filters)
    filters
      .then { |f| deep_compact(f) }
      .then { |f| decode_range_filters(f) }
      .then { |f| decode_array_filters(f) }
  end

  # Decode range filters for specific fields
  def decode_range_filters(filters)
    process_c14_bp_range(filters)
    process_cals_range(filters)
    filters
  end

  def process_c14_bp_range(filters)
    return unless filters.dig(:c14s, :bp)

    filters[:c14s][:bp] = slice_ranges(filters.dig(:c14s, :bp))
  end

  def process_cals_range(filters)
    if filters.dig(:cals, :tpq)
      filters[:cals][:tpq] = slice_ranges([50000, filters.dig(:cals, :tpq)])
    end

    if filters.dig(:cals, :taq)
      filters[:cals][:taq] = slice_ranges([filters.dig(:cals, :taq), 0])
    end
  end

  # Decode array filters for Tom Select compatibility
  def decode_array_filters(filters)
    return filters unless filters.is_a?(Hash)

    filters.transform_values do |value|
      case value
      when Hash then decode_array_filters(value)
      when Array then value.flat_map { |v| v.include?(",") ? v.split(",") : v }
      else value
      end
    end
  end

  # Compact deeply nested structures
  def deep_compact(data)
    case data
    when Hash
      data.transform_values { |value| deep_compact(value) }.compact_blank
    when Array
      data.map { |value| deep_compact(value) }.compact_blank
    else
      data
    end
  end

  # Convert values into range slices
  def slice_ranges(values)
    values.map(&:to_i).each_slice(2).map do |range|
      range.sort!
      range.size == 1 ? range.first..range.first : range.first..range.last
    end
  end
end