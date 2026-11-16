# frozen_string_literal: true

class Site
  # Displays the evidence for a site pair without assuming a one-to-one match.
  class DuplicateMeasurements
    def initialize(sites)
      @groups = sites.to_h do |site|
        measurements = site.c14s.includes(:references, sample: :context).reorder(:lab_identifier, :id)
        [site.id, measurements.group_by { |measurement| comparison_key(measurement) }]
      end
      @shared_keys = @groups.values.map(&:keys).reduce(:&).compact
    end

    def matches
      @matches ||= @shared_keys.map { |key| [key, @groups.transform_values { |groups| groups.fetch(key) }] }
    end

    def unmatched(site)
      @groups.fetch(site.id).except(*@shared_keys).values.flatten
    end

    private

    def comparison_key(measurement)
      fields = [measurement.lab_identifier, measurement.bp, measurement.std]
      fields if fields.none?(&:blank?)
    end
  end
end
