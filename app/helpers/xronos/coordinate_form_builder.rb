# frozen_string_literal: true

module Xronos
  # Bootstrap builder extended with reusable geographic form controls.
  class CoordinateFormBuilder < BootstrapForm::FormBuilder
    # Render coordinate inputs with decimal and DMS modes.
    # Optional options add a country field, country suggestions or disable the map preview.
    def coordinate_fields(latitude_attribute, longitude_attribute, options = {})
      @template.render(
        partial: 'shared/coordinate_fields',
        locals: {
          form: self,
          latitude_attribute:,
          longitude_attribute:,
          **coordinate_field_options(latitude_attribute, longitude_attribute, options)
        }
      )
    end

    private

    def coordinate_field_options(latitude_attribute, longitude_attribute, options)
      {
        latitude_label: options.fetch(:latitude_label, latitude_attribute.to_s.humanize),
        longitude_label: options.fetch(:longitude_label, longitude_attribute.to_s.humanize),
        country_attribute: options[:country_attribute],
        country_suggestion_url: options[:country_suggestion_url],
        map_api_key: options[:map_api_key],
        preview: options.fetch(:preview, true)
      }
    end
  end
end
