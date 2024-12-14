class XronosData
  include ActiveModel::Model

  attr_accessor :xrons
  attr_accessor :filters
  attr_accessor :selects

  def initialize(filters = {}, selects = {})

    self.filters = filters
    @selects = selects

    @xrons = everything
    filter unless @filters.blank?
    select unless @selects.blank?
  end

  def everything
    # TODO: typos, dendros, etc.
    C14
    .left_outer_joins(:c14_lab)
    .joins("LEFT OUTER JOIN cals on (cals.c14_age = c14s.bp AND cals.c14_error = c14s.std)")
      .left_outer_joins(sample: [
        :material,
        :taxon,
        context: [
          site: [
            :site_types
          ]
        ]
    ])
    .all.distinct
  end

  def filters=(value)
    filters = value.to_h
    filters = deep_compact(filters)
    filters = decode_range_filters(filters)
    filters = decode_array_filters(filters)

    @filters = filters
  end

  def filter
    @xrons = @xrons.where(@filters)
  end

  def select
    @xrons = @xrons.select(*@selects).distinct
  end
  
  def filter_value(*args)
    @filters.dig(*args)
  end

  def filter_value_string(*args)
    @filters.dig(*args).join(",") if @filters.dig(*args).present?
  end

  def self.store_data_as_json
      query = <<-SQL
        SELECT json_agg(json_build_object('measurement', subquery)) AS measurements
        FROM (SELECT "data_views".* FROM "data_views") subquery
      SQL

      result = C14.connection.exec_query(query)
      measurements = result[0]['measurements']

      File.open(Rails.root.join('public', 'all_data.json'), 'w') do |file|
        file.write(measurements)
      end
  end
  
  private

  def decode_range_filters(filters)
    if filters.dig(:c14s, :bp).present?
      filters.dig(:c14s, :bp).replace(slice_ranges(filters.dig(:c14s, :bp)))
    end
    
    if filters.dig(:cals).present?
      # Ensure the value for :tpq is replaced with the array
      tpq_value = filters.dig(:cals, :tpq)
      filters[:cals][:tpq] = slice_ranges([50000, tpq_value]) if tpq_value
      #filters[:cals][:tpq] = !nil
      
      # Ensure the value for :taq is replaced with the array
      taq_value = filters.dig(:cals, :taq)
      filters[:cals][:taq] = slice_ranges([taq_value, 0]) if taq_value
    end
    
    return filters
  end

  # Tom Select encodes multiple values in text inputs as a one-length hash with
  # comma-delimited params, rather than the rails param[] notation. 
  # TODO: would be nicer to patch this in tom select
  def decode_array_filters(filters)
    return filters unless filters.is_a?(Hash)
    filters.transform_values { |val| 
      case val
      when Hash then decode_array_filters(val)
      when Array then val.map { |v| v.include?(",") ? v.split(",") : v }.flatten
      else val
      end
    }
  end

  def deep_compact(hash)
    return hash.compact_blank if hash.is_a?(Array)
    hash.transform_values { |h|
      h.is_a?(Hash) | h.is_a?(Array) ? deep_compact(h) : h
    }.compact_blank
  end

  def slice_ranges(x)
    x.map! { |i| i.to_i }
    x.each_slice(2).map { |n| 
      if n.length == 1
        n[0]..n[0]
      else
        n.sort!
        n[0]..n[1] 
      end
    }
  end

end
