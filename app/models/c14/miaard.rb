# frozen_string_literal: true

class C14
  class MIAARD
    SCHEMA = 'miaard'

    FIELDS = %i[
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

    def self.collection(c14s)
      c14s.map { |c14| new(c14) }
    end

    attr_reader :source

    def initialize(c14)
      @source = c14
    end

    def to_h
      {
        lab_code: lab_code,
        lab_id: lab_id_value,
        conventional_age: @source.bp,
        conventional_age_error: @source.std,
        f14c: @source.f14c,
        f14c_error: @source.f14c_error,
        delta_13_c_calculation_method: nil,
        sample_ids: nil,
        sample_material: @source.sample&.material&.name,
        sample_taxon_id: @source.sample&.gbif_taxon_uri,
        sample_taxon_id_confidence: sample_taxon_id_confidence,
        sample_taxon_scientific_name: @source.sample&.taxon_name,
        sample_anatomical_part: nil,
        suspected_sample_contamination: nil,
        suspected_sample_contamination_description: nil,
        sample_location: @source.site&.name,
        decimal_latitude: @source.site&.lat&.to_f,
        decimal_longitude: @source.site&.lng&.to_f,
        coordinate_precision: nil,
        pretreatment_methods: nil,
        pretreatment_method_description: nil,
        pretreatment_method_protocol: nil,
        measurement_method: measurement_method,
        sample_starting_weight: nil,
        pretreatment_yield: nil,
        pretreatment_proportion_yield: nil,
        carbon_proportion: nil,
        delta_13_c: @source.delta_c13,
        delta_13_c_error: @source.delta_c13_std,
        delta_13_c_method: nil,
        suspected_reservoir_effect: nil
      }
    end

    private

    def lab_code
      return nil if @source.lab_id.blank? || @source.lab_id.invalid?

      @source.lab_id.lab_code
    end

    def lab_id_value
      return nil if @source.lab_id.blank? || @source.lab_id.invalid?

      @source.lab_id.lab_number
    end

    def sample_taxon_id_confidence
      return nil if @source.sample&.gbif_taxon_uri.blank?

      true
    end

    def measurement_method
      case @source.method.to_s.strip.downcase
      when 'ams' then 'AMS'
      when 'pims' then 'PIMS'
      when 'conventional' then 'Conventional'
      end
    end
  end
end