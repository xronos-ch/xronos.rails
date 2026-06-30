# frozen_string_literal: true

module Miaard
  class C14Exporter
    LIBBY_MEAN_LIFE = 8033.0

    MIAARD_FIELDS = %i[
      lab_code
      lab_id
      conventional_age
      conventional_age_error
      f14c
      f14c_error
      delta_13_c_calculation_method
      sample_ids
      sample_material
      sample_taxon_id
      sample_taxon_id_confidence
      sample_taxon_scientific_name
      sample_anatomical_part
      suspected_sample_contamination
      suspected_sample_contamination_description
      sample_location
      decimal_latitude
      decimal_longitude
      coordinate_precision
      pretreatment_methods
      pretreatment_method_description
      pretreatment_method_protocol
      measurement_method
      sample_starting_weight
      pretreatment_yield
      pretreatment_proportion_yield
      carbon_proportion
      delta_13_c
      delta_13_c_error
      delta_13_c_method
      suspected_reservoir_effect
    ].freeze

    REQUIRED_FIELDS = %i[
      lab_code
      lab_id
      f14c
      f14c_error
      sample_ids
      sample_material
      sample_taxon_id
      sample_taxon_id_confidence
      pretreatment_methods
      pretreatment_method_description
      pretreatment_method_protocol
      measurement_method
      sample_starting_weight
      pretreatment_yield
      carbon_proportion
      suspected_reservoir_effect
    ].freeze

    def initialize(c14)
      @c14 = c14
    end

    def as_json(*)
      values = {
        lab_code: lab_code,
        lab_id: lab_id,
        conventional_age: c14.bp,
        conventional_age_error: c14.std,
        f14c: derived_f14c,
        f14c_error: derived_f14c_error,
        delta_13_c_calculation_method: nil,
        sample_ids: sample_ids,
        sample_material: nil,
        sample_taxon_id: sample_taxon_id,
        sample_taxon_id_confidence: sample_taxon_id_confidence,
        sample_taxon_scientific_name: sample&.taxon_name,
        sample_anatomical_part: nil,
        suspected_sample_contamination: nil,
        suspected_sample_contamination_description: nil,
        sample_location: site&.name,
        decimal_latitude: site&.lat&.to_f,
        decimal_longitude: site&.lng&.to_f,
        coordinate_precision: nil,
        pretreatment_methods: nil,
        pretreatment_method_description: nil,
        pretreatment_method_protocol: nil,
        measurement_method: measurement_method,
        sample_starting_weight: nil,
        pretreatment_yield: nil,
        pretreatment_proportion_yield: nil,
        carbon_proportion: nil,
        delta_13_c: c14.delta_c13,
        delta_13_c_error: c14.delta_c13_std,
        delta_13_c_method: nil,
        suspected_reservoir_effect: nil
      }

      MIAARD_FIELDS.index_with { |field| values[field] }
    end

    def missing_required_fields
      as_json.select do |field, value|
        REQUIRED_FIELDS.include?(field) && missing_value?(value)
      end.keys
    end

    def completeness_report
      {
        valid_against_current_miaard_required_fields: missing_required_fields.empty?,
        exported_fields: as_json.keys,
        missing_required_fields: missing_required_fields,
        derived_fields: derived_fields
      }
    end

    private

    attr_reader :c14

    def sample
      c14.sample
    end

    def site
      c14.site
    end

    def lab_code
      return nil if c14.lab_id.blank? || c14.lab_id.invalid?

      c14.lab_id.lab_code&.downcase
    end

    def lab_id
      return nil if c14.lab_id.blank? || c14.lab_id.invalid?

      c14.lab_id.lab_number
    end

    def derived_f14c
      return nil if c14.bp.blank?

      Math.exp(-c14.bp.to_f / LIBBY_MEAN_LIFE)
    end

    def derived_f14c_error
      return nil if c14.bp.blank? || c14.std.blank?

      derived_f14c * c14.std.to_f / LIBBY_MEAN_LIFE
    end

    def derived_fields
      fields = []
      fields << :f14c if derived_f14c.present?
      fields << :f14c_error if derived_f14c_error.present?
      fields
    end

    def sample_ids
      [
        c14.lab_identifier,
        "xronos:c14:#{c14.id}",
        sample&.id && "xronos:sample:#{sample.id}"
      ].compact
    end

    def sample_taxon_id
      gbif_id = sample&.taxon&.try(:gbif_id)
      return nil if gbif_id.blank?

      ["gbif:#{gbif_id}"]
    end

    def sample_taxon_id_confidence
      return nil if sample_taxon_id.blank?

      true
    end

    def measurement_method
      case c14.method.to_s.strip.downcase
      when "ams"
        "AMS"
      when "pims"
        "PIMS"
      when "conventional", "beta counting", "gpc", "lsc"
        "Conventional"
      else
        nil
      end
    end

    def missing_value?(value)
      value.nil? || value == "" || value == []
    end
  end
end