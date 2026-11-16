# frozen_string_literal: true

class Site
  # Validates manually entered values before a site merge.
  class CustomDuplicateValues
    class InvalidValue < StandardError; end

    def initialize(values)
      @values = values
    end

    def attributes_for(field)
      case field
      when 'name' then name_attributes
      when 'coordinates' then coordinate_attributes
      when 'country' then country_attributes
      else raise InvalidValue, 'Choose a valid site field.'
      end
    end

    private

    def name_attributes
      name = @values['name'].to_s.strip
      raise InvalidValue, 'Enter a name for the retained site.' if name.blank?

      { name: name }
    end

    def coordinate_attributes
      lat = decimal('lat')
      lng = decimal('lng')
      unless lat&.between?(-90, 90) && lng&.between?(-180, 180)
        raise InvalidValue, 'Enter latitude between -90 and 90 and longitude between -180 and 180 as decimal degrees.'
      end

      { lat: lat, lng: lng }
    end

    def decimal(field)
      value = BigDecimal(@values[field].to_s.strip, exception: false)
      value if value&.finite?
    end

    def country_attributes
      code = @values['country_code'].to_s.strip.upcase
      unless code.match?(/\A[A-Z]{2}\z/) && ISO3166::Country[code]&.alpha2 == code
        raise InvalidValue, 'Enter a valid two-letter country code, such as DK.'
      end

      { country_code: code }
    end
  end
end
