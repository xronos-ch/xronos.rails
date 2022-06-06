class Data
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
    C14.all
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
  end

  def filters=(value)
    filters = value.to_h
    filters = deep_compact(filters)
    #filters = decode_range_filters(filters)
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

  private

  def decode_range_filters(filters)
    if filters.dig(:c14s, :bp).present?
      filters.dig(:c14s, :bp).replace(slice_ranges(filters.dig(:c14s, :bp)))
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
    x.each_slice(2).map { |n| 
      return n[0] if n.length == 1
      n = n.sort
      n[0]..n[1] 
    }
  end

end
